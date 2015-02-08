Feature: Top page
  Scenario: Show top page without login
    When I visit "top" page
    Then It should succeed
