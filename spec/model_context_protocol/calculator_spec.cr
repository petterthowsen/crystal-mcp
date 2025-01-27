require "../spec_helper"

describe ModelContextProtocol::Server::Examples::Calculator do
  it "performs basic arithmetic operations" do
    server = ModelContextProtocol::Server::Examples::Calculator::CalculatorServer.new
    client = ModelContextProtocol::Client.new(
      ModelContextProtocol::Transport::HttpTransport.new("localhost", 8080)
    )

    begin
      # Start server
      server.start

      # Wait a bit for server to start
      sleep(100.milliseconds)

      # Initialize connection
      client.initialize_connection

      # List available tools
      tools, cursor = client.list_tools
      tools.size.should eq(2)
      tools_names = tools.map(&.["name"].as_s).to_a
      tools_names.should contain("add")
      tools_names.should contain("subtract")

      # Test addition
      result = client.invoke_tool(
        "add",
        {
          "a" => JSON::Any.new(2.5),
          "b" => JSON::Any.new(1.7)
        }
      )
      result["result"].as_f.to_f64.should be_close(4.2, 0.001)

      # Test subtraction
      result = client.invoke_tool(
        "subtract",
        {
          "a" => JSON::Any.new(5.0),
          "b" => JSON::Any.new(2.3)
        }
      )
      result["result"].as_f.to_f64.should be_close(2.7, 0.001)

      # Test invalid parameters
      expect_raises(ModelContextProtocol::Server::ToolError) do
        client.invoke_tool(
          "add",
          {
            "a" => JSON::Any.new("not a number"),
            "b" => JSON::Any.new(1.0)
          }
        )
      end

      # Test missing parameters
      expect_raises(ModelContextProtocol::Server::ToolError) do
        client.invoke_tool(
          "add",
          {
            "a" => JSON::Any.new(1.0)
          }
        )
      end

      # Test invalid tool
      expect_raises(Exception, "Tool not found: invalid_tool") do
        client.invoke_tool(
          "invalid_tool",
          {} of String => JSON::Any
        )
      end

    ensure
      client.close
      server.stop
    end
  end
end
