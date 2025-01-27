require "../../spec_helper"

describe ModelContextProtocol::Client::Root do
  it "serializes and deserializes correctly" do
    root = ModelContextProtocol::Client::Root.new(
      uri: "file:///home/user/projects/myproject",
      name: "My Project"
    )

    json = root.to_json
    parsed_root = ModelContextProtocol::Client::Root.from_json(json)

    parsed_root.uri.should eq("file:///home/user/projects/myproject")
    parsed_root.name.should eq("My Project")
  end

  it "handles optional name" do
    root = ModelContextProtocol::Client::Root.new(
      uri: "file:///home/user/projects/myproject"
    )

    json = root.to_json
    parsed_root = ModelContextProtocol::Client::Root.from_json(json)

    parsed_root.uri.should eq("file:///home/user/projects/myproject")
    parsed_root.name.should be_nil
  end
end
