## Some terminology before we begin
The **System** refers to the Bus Station Management System, the main character of this repository.

The **Bus Station** refers to the bus station company that the System is made for.


## Assumptions
1. The Bus Station serves long-trip buses. This assumption is made because it interacts with many different bus companies, which isn't how it typically works for area buses like RapidKL where all buses belong to one company.
2. All `BusDriver`s must hold PSV license, as that's the mandatory license for bus drivers.


# 🚏 Business Rule Document (Bus Management System)

## 📌 General Conventions

* All statuses are controlled by `ENUM` or `VARCHAR2` fields (like `Active`, `Inactive`, `Planned`, etc.).
* Timestamps (`createdAt`, `updatedAt`) ensure audit trail.
* Triggers and procedures ensure data consistency.

---

## 🏢 1. Staff & Station Management Rules

1. **A Staff** can only serve **one Bus Station** (`stationID`) and have only **one Role** (`roleID`).
2. Staff continue to be **active for cleaning duties** even if the `BusStation` they belong to becomes `Inactive`.

---

## 🚍 2. Bus Company & Fleet Rules

1. A **BusCompany** must own at least:

   * One **Bus** (`Bus.companyID`)
   * One **BusDriver** (`BusDriver.companyID`)
   * To be eligible to participate in any BusSchedule planning.
2. A **Bus** can be assigned only if it is `Active`.
3. A **BusMaintenance** can be performed by multiple Staff, and a Bus can have multiple Maintenance records at once.
4. When a `Bus.status` is updated to `Maintenance` via `BusMaintenance`, it is **temporarily blocked from DriverAssignment**.

---

## 🚚 3. Driver & Assignment Rules

1. A **BusDriver** must have a valid, non-expired `licenseExpiry` date.

   * If expired, new license must be uploaded and expiry updated.
2. Only `Active` BusDrivers can be assigned in `DriverAssignment`.
3. A `DriverAssignment` can be set to `Active` only if:

   * The linked `Bus` is `Active`.
   * The linked `BusDriver` is `Active`.
4. After the `BusDriver` is assign to `DriverAssignment` set `BusDriver.status` to `InAssignment`
---

## 🏬 4. Shop & Tenant Management Rules

1. A **Shop** can only belong to **one Tenant**, but a **Tenant** can own multiple Shops.
2. A **Tenant** can make multiple payments for a Shop (tracked in `ShopPayment`).

---

## 🚏 5. Bus Station & Platform Rules

1. A **BusStation** can own:

   * Many **Shops**.
   * Many **Staff**.
   * Many **BusPlaform**.

2. When a `BusStation.status` becomes `Inactive`:

   * All linked `BusPlaform` statuses must be updated to `Inactive`.
   * `Staff` statuses remain unchanged.

3. When a `BusPlaform` becomes `Inactive`:

   * Any `RouteStation` referencing this `plaformID` must be deleted.
   * If the `BusPlaform` belongs to an `Inactive` `BusStation`, it also updates to `Inactive`.


---

## 🗺️ 6. Route & Route Station Rules

1. A **Route** defines start and end platforms.
2. If either start or end platform becomes `Inactive`:

   * The `Route.status` updates to `Inactive`.
   * Or, it must reassign to another `Active` platform.
3. A **RouteStation** lists the platforms (ordered stops) for a Route.
4. If a `BusPlaform` inside a `RouteStation` becomes `Inactive`:

   * The `RouteStation` record must be deleted.

---

## 🕑 7. BusSchedule & Trip Rules

1. A `BusSchedule` can be set to `Active` only if:

   * The linked `Route.status` is `Active`.
   * All `DriverAssignment.status` linked to it is `Active`.

2. **Long trips (>7 hours)** must have at least **2 DriverAssignments** on the same BusSchedule.

```
Example:
BusSchedule: BS_001 (8 hours)
DriverAssignments:
  - AS_001 (D_001 on B_001)
  - AS_002 (D_002 on B_001)
```

3. When a Bus departs a platform, real time is logged in `TripStopLog`.

---

## 🎟️ 8. Ticketing Rules

1. Tickets can only be created if:

   * The `BusSchedule` is `Active`.
2. A Ticket can be booked if:

   * `Ticket.createdAt < BusSchedule.plannedDepartureTime - 7 days`.
   * Ticket type is `bookAllow`.

---

## 💰 9. Payment, Points & Membership Rules

1. **Points** earned or deducted are tracked in `PointTransaction`.
2. Membership Upgrade:
   * If a `Payment` with type `"member_register_fee"` is made,
     then `Customer.type` will be set to `"member"` **permanently**.
3. Membership Downgrade:
   * No automatic downgrade based on point balance.  
     Once upgraded via `"memberregisterfee"`, the customer remains a **member forever**.
---

## ✈️ 10. Refund, Extension & Cancellation Rules

1. If customer cancels a Ticket:

   * Must be done at least `2 days` before `BusSchedule.actualStartTime`.
   * Refund is `70%` of paid price (tracked in `PaymentRecord` as `refund`).
2. Ticket extensions:

   * Check original ticket is `<=2 days` before `BusSchedule.actualStartTime`.
    * Check that the `RouteID` of the new `BusScheduleID` is the **same** as the original `Ticket`’s `BusSchedule.RouteID`.
   * Pay `extension_charge`.
   * Updates Ticket to `booked_extended`.

---

## ⚙️ 11. Maintenance & Shop Termination Rules

When a `BusMaintenanceRecord` record is created:

- Only allow creation if:
  - The associated `Staff.staffID` **starts with 'm'**
  - AND `Staff.status` is **'Active'**
  - AND `Bus.status` is **'inactive'**

- Then:
  - Set the related `Bus.status` to **'Maintenance'**
  - Set the related `BusDriver.status` to **'active' from 'InAssignment'**
  - Set the related `Staff.status` to **'InMaintenance'**
- Else:
  - set `Bus.status` to **'Inactive'**
2. When `BusMaintenanceRecord` status is set to completed:

   * Sets `Bus.status` back to `Active`.
   * Sets related `Staff.status` back to active .

3. When `Tenant` is terminated:

   * All linked `Shop` statuses set to `Vacant`.

## 🚌 Management Procedures & Triggers

### 1️⃣ Platform Management

**Procedure:**
- Update a `BusPlatform` to `Inactive`.

**Triggers:**
- After platform is set to `Inactive`:
  - Find all `RouteStation` entries using this platform and set their status to `Inactive`.
  - If all platforms in a `Route` become `Inactive`, cascade to set the `Route` to `Inactive`.

---

### 2️⃣ Driver Management

**Procedure:**
- Update a `Driver` record to `Inactive`.

**Triggers:**
- Automatically set related:
  - `DriverAssignment` to `Inactive`.
  - `BusSchedule` entries using these assignments to `Inactive`.

---

### 3️⃣ Bus Management

**Procedure:**
- Update a `Bus` record to `Inactive`.

**Triggers:**
- Automatically update all related:
  - `DriverAssignment` to `Inactive`.
  - `BusSchedule` using this bus to `Inactive`.

---

### 4️⃣ Create New Bus Schedule

**Procedure:**
- Insert a new `BusSchedule`.

**Triggers:**
- `BEFORE INSERT`: 
  - Ensure the selected `Route` is `Active`.
  - Ensure the `DriverAssignment` is `Active`.
- `AFTER INSERT`: 
  - Automatically create `Ticket` records with quantity equal to the `Bus.capacity`.

---

### 5️⃣ Bus Station Management

**Procedure:**
- Update a `BusStation` to `Inactive`.

**Triggers:**
- Automatically update all related:
  - `Shop` to `Inactive`.
  - `BusPlatform` to `Inactive`.
  - Indirectly update all `BusSchedule` linked via these platforms to `Inactive`.

---

### 6️⃣ Create New Route

**Procedure:**
- Insert a new `Route`.

**Triggers:**
- `BEFORE INSERT`: 
  - Check that all associated `BusPlatforms` in `RouteStation` entries are `Active`.
- Reject creation if any platform is `Inactive`.

---

### 7️⃣ Add New Route Station

**Procedure:**
- Insert a new `RouteStation`.

**Triggers:**
- `BEFORE INSERT`: 
  - Ensure the `BusPlatform` being added is `Active`.
- Reject insertion if the platform is `Inactive`.

---

### 8️⃣ Update Bus Schedule to Inactive

**Procedure:**
- Update `BusSchedule` status to `Inactive` (e.g. trip canceled by company).

**Triggers:**
- Automatically update:
  - Related `Ticket` status to `cancelled_by_company`.
  - Create a `PaymentRecord` of type `refund` for affected customers.
  - Optionally create a `PointTransaction` to deduct loyalty points earned from this booking.

---

## 🧮 Customer & Ticket Operations

### 9️⃣ Points Earning & Deduction

**Procedure:**
- Insert a new `PointTransaction`.

**Triggers:**
- Automatically update `Customer.pointBalance` by adding the `pointChange` from this record.

---

### 🔟 Ticket Extension

**Procedure:**
- When creating a `PaymentRecord` for `extension_charge` (e.g. RM5 for change of trip).

**Triggers:**
- `BEFORE INSERT`: 
  - Check that original `Ticket.createdAt` is less than 2 days from `BusSchedule.actualStartTime`.
  - Check that the `RouteID` of the new `BusScheduleID` is the **same** as the original `Ticket`’s `BusSchedule.RouteID`.
  - Reject if outside window.
- `AFTER INSERT`: 
  - Update `Ticket` with new `BusScheduleID` and mark as `booked_extended`.

---

### 1️⃣1️⃣ Company Cancels Ticket

**Procedure:**
- When updating `Ticket` status to `cancelled_by_company`.

**Triggers:**
- `AFTER UPDATE`: 
  - Create a `PaymentRecord` of type `refund` (100% of ticket price).

### 1️⃣2️⃣ Customer Cancels Ticket

**Procedure:**
- When updating `Ticket` status to `cancelled_by_customer`.

**Triggers:**
- `BEFORE UPDATE`: 
  - Check that ticket was created at least 2 days before `BusSchedule.actualStartTime`.
  - Reject if too close to departure.
- `AFTER UPDATE`: 
  - Create a `PaymentRecord` of type `refund` (70% of ticket price).

---
### 1️⃣3️⃣ Auto Points After Payment

**Procedure:**
- After creating a `PaymentRecord`.

**Triggers:**
- Automatically create a corresponding `PointTransaction` record.

**Logic:**
- Determine the `PointTransaction.pointChange` based on `PaymentRecord.type`:
  - If `type` is `refund`, `cancel_by_customer`, or `cancel_by_company`:
    - Calculate as: `pointChange = - (PaymentRecord.amount * 100)`.
  - Otherwise (for payments like `extension_charge`, `purchase_ticket`, etc.):
    - Calculate as: `pointChange = + (PaymentRecord.amount * 100)`.
- Insert the new `PointTransaction` with the calculated points and link it to the `Customer`.

---

## ⚙️ Additional Triggers

### Trigger on BusMaintenance

**When:**  
- A `BusMaintenance` record is inserted.

**Then:**  
- Update related `Bus.status` to `Maintenance`.

**Also:**  
- When maintenance is completed (by `remarks` containing `"completed"` or a dedicated `status` field),
- Set `Bus.status` back to `Active`.

---

###  Trigger on Tenant

**When:**  
- A `Tenant` record is set to `Terminated`.

**Then:**  
- Update all related `Shop` records linked to this `Tenant` to `Vacant`.

---

### Trigger on Ticket (Prevent Overbooking)

**BEFORE INSERT:**  
- Check if total number of existing `Ticket` records for this `BusSchedule` is **less than** the `Bus.capacity`.

**If exceeded:**  
- Reject insert to prevent overbooking.

---

### Trigger on TripStopLog

**When:**  
- All planned stops are logged for a `BusSchedule` (compare `TripStopLog` count with planned stops).

**Then:**  
- Optionally mark `BusSchedule` as `Completed` or trigger notifications / follow-up actions.

---


## Tables

### Reference data
#### `StaffRole`
Roles (e.g. "Cleaner", "Driver", etc.) and their descriptions.

#### `BusCompany`
Bus companies that have registered with the Bus Station to use our platforms.

### Customer management
#### `Customer`
People who buy tickets via the System, or who buy things at the shops managed by the Bus Station.

Customers can be non-members or members. A customer needs to pay a RM10 membership fee to become a member. The `membershipStatus` attribute indicates whether a customer is a `guest` (not a member) or a `member`.

The `pointBalance` attribute is only meaningful for `member`s. For a `guest`, the value of `pointBalance` is always `0`.

### Staff management
#### `Staff`
Records people who work for the Bus Station, including shop counter staff, washroom cleaners, etc.

<!-- The attributes `companyID`, `licenseNo`, and `licenseType` are meant for drivers, and therefore should be left `null` for non-driver staff. `companyID` indicates which [`BusCompany`](#buscompany) the driver belongs to. -->

`roleID` references the [`StaffRole`](#staffrole) table, which records descriptions of roles, such as cleaners, counter staff, etc.

### Location and route management
#### `BusStation`
All the bus stations that are managed using the System. A [`BusStation`](#busstation) contains multiple [`BusPlatform`s](#busplatform).

#### `BusPlatform`
A [`BusStation`](#busstation) has multiple platforms. Each platform serves a different type of buses (e.g. travel, business, etc.).

#### `Route`
Records bus routes: from where to where? *Does not record "when" (i.e. schedule)* -- that is handled by [`BusSchedule`](#busschedule). 

#### `RouteStation`
Defines the order of [`BusPlatform`s](#busplaform) (that buses stop by) along a [`Route`](#route).

*Example:* for `routeID: 42`, the following records may exist:
- `{ routeID: 42, stopOrder: 1, platformID: 'P103' }`
- `{ routeID: 42, stopOrder: 2, platformID: 'P009' }`
- `{ routeID: 42, stopOrder: 3, platformID: 'P126' }`

which means that a bus travelling along route `42` will stop by platforms `P103`, `P009`, `P126` in that order.


### Bus fleet management
#### `Bus`
Includes license plates of buses.

#### `BusMaintenance`
Records maintenance services provided by the Bus Station to buses (at a charge). Attributes include the type of maintenance service and charges incurred.

### Schedule and operations
#### `BusSchedule`
Records planned arrival and departure times for each [route](#route). (These times may not reflect the actual time of arrival and departure.) 

#### `DriverAssignment`
Records assignments of buses (and the driver) to [bus schedules](#busschedule). 

#### `TripStopLog`
A log of when a bus departs from a designated [route](#route)'s origin and arrives at the destination. (*Actual* arrival and departure time as opposed to the *planned* arrival and departure times recorded by [`BusSchedule`](#busschedule))

### Payment system
#### `Payment`
Records customer payments, including method, amount, loyalty points used, and status for various transaction types (e.g., ticket, membership, refund).

#### `PointTransaction`
Tracks loyalty point activities for customers, such as earning, redemption, and refunds, often linked to payment records.

### Ticketing system
#### `Ticket`
Represents a bus booking by a customer for a specific bus schedule, with pricing, seat info, and support for cancellation (which may/may not include refund) and extension.

### Shop and Tenant Management
#### `Tenant`
Stores information about individuals or companies renting shop lots in bus stations, including contact and status details.

#### `Shop`
Defines a shop lot at a bus station, linking it to tenants, with details on rental fees, contract periods, and occupancy status.

#### `ShopPayment`
Captures rental-related payments from tenants for shops, including payment type (e.g., rental, deposit), method, and status.

## Relationships
1. Bus Company to Bus and Staff Relationship:
BusCompany {1 → \*} Bus
BusCompany {1 → \*} Staff

2. Bus Maintenance to Bus and Staff Relationship:
BusMaintenance {\* → 1/0} Bus
BusMaintenance {\* → 1/0} Staff

3. Staff to StaffRole and DriverAssignment Relationship:
Staff {\* → 1/0} StaffRole
Staff {1/0 → \*} DriverAssignment

4. Bus to DriverAssignment:
Bus {1/0 → \*} DriverAssignment

5. DriverAssignment to BusSchedule:
DriverAssignment {\* → 1} BusSchedule

6. Ticket to BusSchedule:
Ticket {1 → \*} BusSchedule

7. BusSchedule to TripStopLog and Route:
BusSchedule {1 → \*} TripStopLog
BusSchedule {\* → 1} Route

8. BusPlaform to TripStopLog and RouteStation:
BusPlaform {1 → \*} TripStopLog
BusPlaform {1 → \*} RouteStation

9. BusStation to BusPlaform:
BusStation {1 → \*} BusPlaform

10. Route to RouteStation:
Route {1 → \*} RouteStation

11. Shop to BusStation:
Shop {\* → 1/0} BusStation

12. ShopPayment to Shop:
ShopPayment {\* → 1/0} Shop

13. PointTransaction to Customer and Payment:
PointTransaction {\* → 1} Customer
PointTransaction {1 → 1} Payment

14. Payment to Customer, PointTransaction and Ticket:
Payment {1 → 1} PointTransaction
Payment {\* → 1} Customer
Payment {1 → \*} Ticket

15. Customer to Ticket:
Customer {1 → \*} Ticket
