Rails.application.config.filter_parameters += [
  :api_key,
  :token,
  :github_token,
  :openai_api_key
]
