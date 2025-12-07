@Authorized
Feature: FAISS support tests

  Background:
    Given The service is started locally
      And REST API service prefix is /v1

  Scenario: Query vector db using the file_search tool
    Given The system is in default state
    And I set the Authorization header to Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ikpva
    When I use "query" to ask question with authorization header
    """
    {"query": "How do you do great work? Please search the documents to answer this question. Also, who is the author?", "system_prompt": "You are an assistant"}
    """
     Then The status code of the response is 200
      And The response should contain following fragments
          | Fragments in LLM response |
          | Graham                    |
