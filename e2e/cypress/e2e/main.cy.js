/* global describe, beforeEach, cy, it */
/// <reference types="cypress" />

describe('esprsso', () => {
  beforeEach(() => {
    cy.visit('/')

    cy.intercept('POST', '**/api/*', { statusCode: 200 }).as('api')
  })

  it('Send a on request on "An" click', () => {
    cy.get('button:contains("An")').click()

    cy.wait('@api').its('request.url')
      .should('match', /.*\/api\/on/)
  })

  it('Send a off request on "Aus" click', () => {
    cy.get('button:contains("Aus")').click()

    cy.wait('@api').its('request.url')
      .should('match', /.*\/api\/off/)
  })
})
