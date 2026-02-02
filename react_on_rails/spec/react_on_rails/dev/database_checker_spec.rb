# frozen_string_literal: true

require "react_on_rails/dev/database_checker"
require "stringio"

RSpec.describe ReactOnRails::Dev::DatabaseChecker do
  describe ".check_database" do
    before do
      # Suppress output during tests
      allow($stdout).to receive(:puts)
    end

    # Helper to create a mock Process::Status
    def mock_status(success:)
      status = instance_double(Process::Status)
      allow(status).to receive(:success?).and_return(success)
      status
    end

    context "when database is accessible" do
      it "returns true" do
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return(["DATABASE_OK\n", "", mock_status(success: true)])

        # Mock the migration check
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "db:migrate:status")
          .and_return(["", "", mock_status(success: false)])

        expect(described_class.check_database).to be true
      end

      it "prints success message" do
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return(["DATABASE_OK\n", "", mock_status(success: true)])

        allow(Open3).to receive(:capture3)
          .with("bin/rails", "db:migrate:status")
          .and_return(["", "", mock_status(success: false)])

        output = capture_stdout { described_class.check_database }
        expect(output).to include("Database is accessible")
      end
    end

    context "when database does not exist" do
      it "returns false" do
        error_output = "NO_DATABASE\nDatabase 'myapp_development' does not exist\n"
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return([error_output, "", mock_status(success: true)])

        expect(described_class.check_database).to be false
      end

      it "prints helpful error message with setup commands" do
        error_output = "NO_DATABASE\nDatabase 'myapp_development' does not exist\n"
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return([error_output, "", mock_status(success: true)])

        output = capture_stdout { described_class.check_database }

        expect(output).to include("Database not set up")
        expect(output).to include("db:setup")
        expect(output).to include("db:create")
      end
    end

    context "when database connection fails" do
      it "returns false" do
        error_output = "CONNECTION_ERROR\nCould not connect to server\n"
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return([error_output, "", mock_status(success: true)])

        expect(described_class.check_database).to be false
      end

      it "prints helpful error message with server start commands" do
        error_output = "CONNECTION_ERROR\nCould not connect to server\n"
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return([error_output, "", mock_status(success: true)])

        output = capture_stdout { described_class.check_database }

        expect(output).to include("Database connection failed")
        expect(output).to include("PostgreSQL")
        expect(output).to include("MySQL")
        expect(output).to include("brew services start")
      end
    end

    context "when Rails returns an error" do
      it "returns false when runner fails" do
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return(["", "LoadError: cannot load such file", mock_status(success: false)])

        expect(described_class.check_database).to be false
      end

      it "prints error information" do
        error_output = "RAILS_ERROR\nNoMethodError\nundefined method"
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return([error_output, "", mock_status(success: true)])

        output = capture_stdout { described_class.check_database }

        expect(output).to include("Could not verify database")
        expect(output).to include("bundle install")
      end
    end

    context "when bin/rails is not found" do
      it "returns true to allow server to start and show the real error" do
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_raise(Errno::ENOENT)

        expect(described_class.check_database).to be true
      end
    end

    context "when migrations are pending" do
      it "prints a warning but returns true" do
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return(["DATABASE_OK\n", "", mock_status(success: true)])

        migration_output = <<~OUTPUT
          Status   Migration ID    Migration Name
            up     20240101000000  Create users
           down    20240102000000  Add email to users
        OUTPUT
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "db:migrate:status")
          .and_return([migration_output, "", mock_status(success: true)])

        output = capture_stdout { described_class.check_database }

        expect(output).to include("Pending migrations")
        expect(output).to include("db:migrate")
        expect(described_class.check_database).to be true
      end
    end

    context "when database check returns unexpected output" do
      it "returns true if DATABASE_OK is found anywhere in output" do
        allow(Open3).to receive(:capture3)
          .with("bin/rails", "runner", anything)
          .and_return(["Some warning\nDATABASE_OK\n", "", mock_status(success: true)])

        allow(Open3).to receive(:capture3)
          .with("bin/rails", "db:migrate:status")
          .and_return(["", "", mock_status(success: false)])

        expect(described_class.check_database).to be true
      end
    end
  end

  # Helper methods
  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    # Remove the stub for this specific test
    allow($stdout).to receive(:puts).and_call_original
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
