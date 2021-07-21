# Robot resources for Blueriq Modeling Platform

[Robot Framework](https://robotframework.org/) is a generic open source automation framework. It can be used for test automation and robotic process automation (RPA).

At Blueriq we've created these resources as a mean to enable quick and robust **automated regression tests**.

## Goal

Using these resources you'll be able to quickly get started creating automated tests that **don't depend on the GUI of Blueriq applications**.

This is achieved by using our [**UI REST API**](https://my.blueriq.com/display/DOC/UI+REST+API+V2) on which you can read more at our Community space.

## Benefits

The main benefit is the drastic improvement in duration time in comparison to automated test that have been **written against GUI components**.

This problem is tool-agnostic as it is possible to write non-performant tests with tools like Cypress.io, Cucumber or even Robot. 

You can determine whether or not this is the case if there are any **"waitForElement/waitForBlueriqElement"** components.