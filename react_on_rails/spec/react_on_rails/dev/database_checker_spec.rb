# frozen_string_literal: true

require "react_on_rails/dev/database_checker"
require "stringio"

# Create a test helper class for mocking ActiveRecord connection
class MockConnection
  def execute(query); end
end

# Create a test helper class for mocking ActiveRecord::Base
class MockActiveRecordBase
  def self.connection; end
end

RSpec.describe ReactOnRails::Dev::DatabaseChecker do
  describe ".check_database" do
    context "when Rails/ActiveRecord is not available" do
      before do
        hide_const("Rails")
        hide_const("ActiveRecord::Base")
      end

      it "returns true without checking database" do
        expect(described_class.check_database).to be true
      end
    end

    context "when Rails is available" do
      let(:mock_connection) { instance_double(MockConnection) }

      before do
        stub_const("Rails", class_double(Object))
        stub_const("ActiveRecord::Base", class_double(MockActiveRecordBase, connection: mock_connection))
        stub_const("ActiveRecord::NoDatabaseError", Class.new(StandardError))
        stub_const("ActiveRecord::PendingMigrationError", Class.new(StandardError))
        stub_const("ActiveRecord::ConnectionNotEstablished", Class.new(StandardError))
        stub_const("ActiveRecord::StatementInvalid", Class.new(StandardError))
      end

      context "when database is ready" do
        before do
          allow(mock_connection).to receive(:execute).with("SELECT 1").and_return(true)
        end

        it "returns true" do
          output = capture_stdout do
            expect(described_class.check_database).to be true
          end

          expect(output).to include("Checking database")
          expect(output).to include("Database is ready")
        end
      end

      context "when database does not exist" do
        before do
          allow(mock_connection).to receive(:execute).and_raise(ActiveRecord::NoDatabaseError)
        end

        it "returns false and shows db:setup guidance" do
          output = capture_stdout do
            expect(described_class.check_database).to be false
          end

          expect(output).to include("Database not set up")
          expect(output).to include("database does not exist")
          expect(output).to include("bin/rails db:setup")
          expect(output).to include("bin/rails db:create")
        end
      end

      context "when migrations are pending" do
        before do
          allow(mock_connection).to receive(:execute).and_raise(ActiveRecord::PendingMigrationError)
        end

        it "returns false and shows db:migrate guidance" do
          output = capture_stdout do
            expect(described_class.check_database).to be false
          end

          expect(output).to include("Database not set up")
          expect(output).to include("pending migrations")
          expect(output).to include("bin/rails db:migrate")
        end
      end

      context "when connection cannot be established" do
        before do
          allow(mock_connection).to receive(:execute).and_raise(
            ActiveRecord::ConnectionNotEstablished.new("Connection refused")
          )
        end

        it "returns false and shows connection troubleshooting" do
          output = capture_stdout do
            expect(described_class.check_database).to be false
          end

          expect(output).to include("Database not set up")
          expect(output).to include("Could not connect")
          expect(output).to include("database server is running")
          expect(output).to include("database.yml")
        end
      end

      context "when a statement error occurs" do
        before do
          allow(mock_connection).to receive(:execute).and_raise(
            ActiveRecord::StatementInvalid.new("Unknown error")
          )
        end

        it "returns false and shows connection troubleshooting" do
          output = capture_stdout do
            expect(described_class.check_database).to be false
          end

          expect(output).to include("Database not set up")
          expect(output).to include("Could not connect")
        end
      end

      context "when an unexpected error occurs" do
        before do
          allow(mock_connection).to receive(:execute).and_raise(StandardError.new("Something unexpected"))
        end

        it "returns true to allow apps without databases to continue" do
          output = capture_stdout do
            expect(described_class.check_database).to be true
          end

          # Should show the check header but not fail
          expect(output).to include("Checking database")
        end

        it "outputs a warning when DEBUG is enabled" do
          allow(ENV).to receive(:[]).with("DEBUG").and_return("true")
          expect { described_class.check_database }.to output(/Database check warning/).to_stderr
        end
      end
    end
  end

  # Helper methods
  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
