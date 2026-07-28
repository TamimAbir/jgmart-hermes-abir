# Financial Model

**Currency:** BDT (৳)  
**Market:** Japan Garden City, Dhaka (initial)  
**Status:** Paper model — replace with live data ASAP

## Assumptions (Pilot Scale)

| Parameter | Conservative | Base |
|-----------|--------------|------|
| Daily orders (Month 1) | 15–30 | 40–60 |
| AOV | ৳700 | ৳800 |
| Delivery fee | ৳30 | ৳30 |
| Blended commission | 8–11% | 11% |

These are **targets**, not forecasts based on transactions.

## Unit Economics (Illustrative)

```
AOV:                 ৳800
Commission (~11%):   ৳88
Delivery fee:        ৳30
Gross intake:        ৳118

Variable costs (rider, pack, fuel, misc):  must be measured live
Target: positive contribution after variable costs
```

Break-even volume depends on fixed monthly burn (hosting, tools, founder draw, float). Measure real burn weekly during pilot.

## Cost Structure (Pilot)

### Fixed (monthly, order-of-magnitude)
| Item | Notes |
|------|-------|
| Hosting / Supabase / domain | Low hundreds of BDT to low thousands |
| WhatsApp Business tooling | Depends on volume |
| Founder / ops time | Largest real cost |

### Variable (per order)
| Item | Notes |
|------|-------|
| Rider payout | Primary variable cost |
| Packaging | |
| Fuel / logistics | |

## What To Track From Day 1

- Orders per day
- AOV and cancellation rate
- On-time delivery %
- Contribution per order (actual)
- Cash position / float
- Partner settlement cycle

## Funding

- Pre-seed discussion should wait until **real order data** exists for at least 2–4 weeks.
- Use-of-funds tables in older decks are directional only until then.

## Source Files

CSV calculators live under `assets/documents/`. Treat them as worksheets, not audited financials.

---

*Update this file when live metrics replace assumptions. Canonical status: `docs/STATUS.md`.*
