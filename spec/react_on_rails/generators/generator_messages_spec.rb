describe GeneratorMessages do
  it "has an empty errors array" do
    expect(GeneratorMessages.messages).to be_empty
  end

  it "has a method that can add errors" do
    GeneratorMessages.add_error "Test error"
    expect(GeneratorMessages.messages)
      .to match_array([GeneratorMessages.format_error("Test error")])
  end
end
