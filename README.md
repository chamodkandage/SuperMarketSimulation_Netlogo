# NetLogo Supermarket Simulation

This simulation is designed to model and analyze customer behavior in a supermarket environment using **agent-based modeling (ABM)** in NetLogo. The model evaluates **checkout counter optimization**, **potential missed income**, and **actual revenue**, making it highly relevant for operational decision-making in **low- and middle-income countries (LMICs)**.

---

## Simulation Objectives

- Determine the **optimal number of checkout counters** for varying customer loads.
- Maximize actual income while **minimizing potential missed revenue**.
- Understand customer decision-making under queue stress conditions.

---

## Business Problem

Supermarkets with limited resources often struggle to balance service efficiency and revenue optimization. Long queues can lead to lost customers and revenue. This simulation addresses:
- What is the **ideal number of counters** for a given customer inflow?
- How do **queue dynamics** influence purchasing decisions?
- How much income is potentially missed due to long waiting times?

---

## Simulation Design

### Zones

- **Entrance Zone (Yellow)** – Customer entry point
- **Product Shelves (Blue)** – Increase basket value by Rs. 1,000 on contact
- **General Area (Black)** – Customer wandering area
- **Checkout Counters (Red)** – Service points with queues
- **Exit without Purchase (Cyan)** – For customers who abandon shopping
- **Checkout Zone (Grey)** – Decision point

### Agents (Turtles)

| Property             | Description                                         |
|----------------------|-----------------------------------------------------|
| `blue-hits`          | Number of product shelf hits (Rs. 1,000 each)       |
| `assigned-counter`   | Counter assigned for checkout                       |
| `waiting-time`       | Time spent in the queue                             |
| `heading-to-counter?`| Whether heading toward the checkout                 |
| `going-to-cyan?`     | Whether exiting without purchasing                  |

### Patches (Environment Units)

| Patch Property | Description                              |
|----------------|------------------------------------------|
| `queue`        | Customers assigned to this counter       |
| `serving-timer`| Countdown timer for each checkout service|

---

## Parameters

### Input Sliders

- `Number-of-customers` – Total agents to simulate
- `Number-of-counters` – Number of active checkout counters

### Output Monitors

- `Customers Who Purchased`
- `Customers Who Left Without Purchasing`
- `Total Income from Purchases (Rs '000)`
- `Potential Missed Income (Rs '000)`

---

## Agent Interactions

1. Customers enter from yellow zones and wander the store.
2. On hitting a blue patch (shelf), their `blue-hits` increases by 1 (Rs. 1,000).
3. They then attempt checkout:
   - If `blue-hits < queue length`, they exit via the **cyan zone**.
   - Otherwise, they join the **shortest queue**.
4. At checkout, customers are served and `income` is updated.
5. Departures and missed opportunities are logged for evaluation.

---

## Visualization

The interface shows:
- **Real-time simulation** of customer flow
- **Plots** comparing:
  - Total potential income vs.
  - Actual income over time



---

## Evaluation Methodology

- **Verification:** Model accurately follows the logical agent behaviors.
- **Validation:** Simulated outcomes are compared against real-world supermarket data.

---

## Assumptions

- Each shelf hit = Rs. 1,000 value added.
- Checkout time = **5 ticks per customer**, fixed.
- Customers prefer the **shortest available queue**.
- They **exit if waiting time exceeds value of items** in their basket.

---

## Requirements

- **NetLogo 6.2 or higher**
- No external dependencies

---

## How to Run

1. Open `supermarket.nlogo` in NetLogo.
2. Adjust the sliders:
   - Number of customers
   - Number of counters
3. Click `setup`, then `go`.
4. Observe income metrics and agent behavior.

---

## References

- Adapted from: [`terman37/NetLogo-Agent_Based_Modeling-SuperMarket`](https://github.com/terman37/NetLogo-Agent_Based_Modeling-SuperMarket)

---






