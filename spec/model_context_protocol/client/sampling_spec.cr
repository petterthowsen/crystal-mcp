require "../../spec_helper"

describe ModelContextProtocol::Client::MessageContent do
  describe ModelContextProtocol::Client::MessageContent::TextContent do
    it "serializes and deserializes correctly" do
      content = ModelContextProtocol::Client::MessageContent::TextContent.new(
        text: "Hello, world!"
      )

      json = content.to_json
      parsed_content = ModelContextProtocol::Client::MessageContent::Base.from_json(json)

      parsed_content.should be_a(ModelContextProtocol::Client::MessageContent::TextContent)
      parsed_content.as(ModelContextProtocol::Client::MessageContent::TextContent).text.should eq("Hello, world!")
    end
  end

  describe ModelContextProtocol::Client::MessageContent::ImageContent do
    it "serializes and deserializes correctly" do
      content = ModelContextProtocol::Client::MessageContent::ImageContent.new(
        data: "base64data",
        mime_type: "image/jpeg"
      )

      json = content.to_json
      parsed_content = ModelContextProtocol::Client::MessageContent::Base.from_json(json)

      parsed_content.should be_a(ModelContextProtocol::Client::MessageContent::ImageContent)
      image_content = parsed_content.as(ModelContextProtocol::Client::MessageContent::ImageContent)
      image_content.data.should eq("base64data")
      image_content.mime_type.should eq("image/jpeg")
    end
  end
end

describe ModelContextProtocol::Client::ModelPreferences do
  it "serializes and deserializes correctly" do
    preferences = ModelContextProtocol::Client::ModelPreferences.new(
      hints: [
        ModelContextProtocol::Client::ModelPreferences::ModelHint.new(name: "claude-3-sonnet")
      ],
      cost_priority: 0.3,
      speed_priority: 0.8,
      intelligence_priority: 0.5
    )

    json = preferences.to_json
    parsed_preferences = ModelContextProtocol::Client::ModelPreferences.from_json(json)

    parsed_preferences.hints.size.should eq(1)
    parsed_preferences.hints[0].name.should eq("claude-3-sonnet")
    parsed_preferences.cost_priority.should eq(0.3)
    parsed_preferences.speed_priority.should eq(0.8)
    parsed_preferences.intelligence_priority.should eq(0.5)
  end
end

describe ModelContextProtocol::Client::Message do
  it "serializes and deserializes correctly" do
    content = ModelContextProtocol::Client::MessageContent::TextContent.new(
      text: "Hello, world!"
    )

    message = ModelContextProtocol::Client::Message.new(
      role: "user",
      content: content,
      model: "claude-3-sonnet",
      stop_reason: "endTurn"
    )

    json = message.to_json
    parsed_message = ModelContextProtocol::Client::Message.from_json(json)

    parsed_message.role.should eq("user")
    parsed_message.content.should be_a(ModelContextProtocol::Client::MessageContent::TextContent)
    parsed_message.content.as(ModelContextProtocol::Client::MessageContent::TextContent).text.should eq("Hello, world!")
    parsed_message.model.should eq("claude-3-sonnet")
    parsed_message.stop_reason.should eq("endTurn")
  end
end
