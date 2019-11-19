module FeatureTestHelper
  def missing_page_text_custom_error(text, page_path, page_text = "")

    if page_text.present?
      page_text = %(, instead got: #{page_text})
    end

    "expected to find \"#{text}\" on: #{page_path}#{page_text}"
  end

  def found_page_text_custom_error(text, page_path)
    "did not expect to find \"#{text}\" on: #{page_path}"
  end
end

RSpec.configure do |c|
  c.include FeatureTestHelper
end
