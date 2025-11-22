# frozen_string_literal: true

require "react_on_rails/dev/service_checker"
require "tempfile"
require "yaml"

RSpec.describe ReactOnRails::Dev::ServiceChecker do
  describe ".check_services" do
    context "when config file does not exist" do
      it "returns true without checking services" do
        expect(described_class.check_services(config_path: "nonexistent.yml")).to be true
      end
    end

    context "when config file is empty" do
      it "returns true" do
        with_temp_config({}) do |path|
          expect(described_class.check_services(config_path: path)).to be true
        end
      end
    end

    context "when config file has no services" do
      it "returns true" do
        with_temp_config({ "services" => {} }) do |path|
          expect(described_class.check_services(config_path: path)).to be true
        end
      end
    end

    context "when config file has invalid YAML" do
      it "prints warning and returns true" do
        Tempfile.create(["invalid", ".yml"]) do |file|
          file.write("invalid: yaml: content:")
          file.flush

          expect { described_class.check_services(config_path: file.path) }
            .to output(/Failed to load/).to_stdout
          expect(described_class.check_services(config_path: file.path)).to be true
        end
      end
    end

    context "when all services are running" do
      it "returns true and prints success messages" do
        config = {
          "services" => {
            "test_service" => {
              "check_command" => "echo 'RUNNING'",
              "expected_output" => "RUNNING",
              "description" => "Test service"
            }
          }
        }

        with_temp_config(config) do |path|
          output = capture_stdout do
            expect(described_class.check_services(config_path: path)).to be true
          end

          expect(output).to include("Checking required services")
          expect(output).to include("test_service")
          expect(output).to include("All services are running")
        end
      end
    end

    context "when some services are not running" do
      it "returns false and prints failure messages with start commands" do
        config = {
          "services" => {
            "failing_service" => {
              "check_command" => "false",
              "description" => "Service that fails",
              "start_command" => "start-service",
              "install_hint" => "brew install service"
            }
          }
        }

        with_temp_config(config) do |path|
          output = capture_stdout do
            expect(described_class.check_services(config_path: path)).to be false
          end

          expect(output).to include("Some services are not running")
          expect(output).to include("failing_service")
          expect(output).to include("Service that fails")
          expect(output).to include("start-service")
          expect(output).to include("brew install service")
        end
      end
    end

    context "when check_command succeeds without expected_output" do
      it "returns true if command exits successfully" do
        config = {
          "services" => {
            "test_service" => {
              "check_command" => "true"
            }
          }
        }

        with_temp_config(config) do |path|
          expect(described_class.check_services(config_path: path)).to be true
        end
      end
    end

    context "when check_command output does not match expected_output" do
      it "returns false" do
        config = {
          "services" => {
            "test_service" => {
              "check_command" => "echo 'WRONG'",
              "expected_output" => "RIGHT"
            }
          }
        }

        with_temp_config(config) do |path|
          expect(described_class.check_services(config_path: path)).to be false
        end
      end
    end

    context "when check_command is missing" do
      it "treats the service as failed" do
        config = {
          "services" => {
            "test_service" => {
              "description" => "Service without check command"
            }
          }
        }

        with_temp_config(config) do |path|
          expect(described_class.check_services(config_path: path)).to be false
        end
      end
    end

    context "with multiple services" do
      it "checks all services and reports failures" do
        config = {
          "services" => {
            "passing_service" => {
              "check_command" => "true",
              "description" => "This passes"
            },
            "failing_service" => {
              "check_command" => "false",
              "description" => "This fails"
            }
          }
        }

        with_temp_config(config) do |path|
          output = capture_stdout do
            expect(described_class.check_services(config_path: path)).to be false
          end

          expect(output).to include("passing_service")
          expect(output).to include("failing_service")
          expect(output).to include("Some services are not running")
        end
      end
    end

    context "when check_command raises an error" do
      it "treats the service as failed" do
        config = {
          "services" => {
            "test_service" => {
              "check_command" => "nonexistent-command-xyz123",
              "description" => "Service with invalid command"
            }
          }
        }

        with_temp_config(config) do |path|
          expect(described_class.check_services(config_path: path)).to be false
        end
      end
    end

    context "when check_command outputs to stderr" do
      it "captures stderr in output" do
        config = {
          "services" => {
            "test_service" => {
              "check_command" => "echo 'ERROR' >&2",
              "expected_output" => "ERROR"
            }
          }
        }

        with_temp_config(config) do |path|
          expect(described_class.check_services(config_path: path)).to be true
        end
      end
    end

    context "when check_command outputs to both stdout and stderr" do
      it "captures both streams" do
        config = {
          "services" => {
            "test_service" => {
              "check_command" => "echo 'OUT' && echo 'ERR' >&2",
              "expected_output" => "OUT"
            }
          }
        }

        with_temp_config(config) do |path|
          expect(described_class.check_services(config_path: path)).to be true
        end
      end

      it "can match against stderr output" do
        config = {
          "services" => {
            "test_service" => {
              "check_command" => "echo 'OUT' && echo 'ERR' >&2",
              "expected_output" => "ERR"
            }
          }
        }

        with_temp_config(config) do |path|
          expect(described_class.check_services(config_path: path)).to be true
        end
      end
    end
  end

  # Helper methods
  def with_temp_config(config)
    Tempfile.create(["test-services", ".yml"]) do |file|
      file.write(YAML.dump(config))
      file.flush
      yield file.path
    end
  end

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
