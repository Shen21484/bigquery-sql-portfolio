# Supply Chain Cost & Risk Analysis

## Overview
This SQL project extracts key dimensions from the database, performs preliminary calculations, and generates a detailed cost breakdown. The final result is a rolling 3-month analysis segmented by country routes, comparing the ratio of risk costs between Standard and Oversized cargo.

## Key Features
* **Data Transformation:** Cleans raw carrier data and standardizes currency exchange rates.
* **Cost Attribution:** Breaks down total costs into base rates, surcharges (fuel/green fees), and risk-related costs.
* **Risk Analysis:** Calculates a "Risk Percentage" (Risk Cost / Total Cost) to flag high-risk routes.
