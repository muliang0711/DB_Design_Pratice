## Some terminology before we begin
The **System** refers to the Bus Station Management System, the main character of this repository.

The **Bus Station** refers to the bus station company that the System is made for.


## Assumptions
1. The Bus Station serves long-trip buses. This assumption is made because it interacts with many different bus companies, which isn't how it typically works for area buses like RapidKL where all buses belong to one company.
2. All `BusDriver`s must hold PSV license, as that's the mandatory license for bus drivers.


# 🚏 Business Rule Document (Bus Management System)

## 📌 General Conventions

* All status fields use `ENUM` or controlled `VARCHAR2` values (e.g. `Active`, `Inactive`, `Planned`, `Cancelled`).
* `createdAt` and `updatedAt` timestamps are automatically managed to ensure audit trail.
* Foreign keys and constraints enforce referential integrity.
* Indexing and composite PKs (e.g. in `MaintenanceStaffAssignment`) prevent duplicate relationships.

---

## 🏢 1. Staff & Station Management Rules

1. Each **Staff**:
   * Must have a unique `ICPassportNo`.
   * Can belong to **one BusStation** (`stationID`) and hold **one Role** (`roleID`).
2. When a `BusStation` becomes `Inactive`:
   * Its related `BusPlatform` become `Inactive`.
   * `Staff` remain unchanged (can be reassigned later).

---

## 🧑‍🔧 2. Shop & Tenant Management Rules

1. A **Tenant** may own multiple Shops.
2. A **Shop**:
   * Belongs to exactly **one Tenant**.
   * When `Tenant.status = 'Terminated'`, all associated `Shop.status` are updated to `Vacant`.
3. Multiple payments (`ShopPayment`) can be recorded for the same Shop, for `Rental`, `Deposit` or `Penalty`.

---

## 🚏 3. Bus Station & Platform Rules

1. A **BusStation** can own:
   * Many **BusPlatforms**, many **Shops**, and many **Staff**.
2. When a `BusPlatform` becomes `Inactive`:
   * All related `RouteStation` records are deleted to prevent broken routes.

---

## 🗺️ 4. Route & Route Station Rules

1. A **Route** defines start and end points (`startPoint`, `endPoint`).
2. A `RouteStation`:
   * Must refer to an active `BusPlatform`.
3. If a `RouteStation` platform becomes `Inactive`, the `RouteStation` record is removed.
4. If either start or end point of a `Route` becomes `Inactive`:
   * The `Route.status` updates to `Inactive` or must be reassigned.

---

## 🚍 5. Bus Company & Fleet Rules

1. A **BusCompany** must have at least:
   * One **Bus**.
   * One **BusDriver**.
2. A **Bus**:
   * Must be `Active` to be assigned in `DriverAssignment`.
   * When under maintenance (`status = 'In_Maintenance'`), cannot be assigned to a trip.
3. `Bus.status` values:
   * `Active`: available for scheduling.
   * `In_Maintenance`: blocked from assignment.
   * `Retired`: permanently unassigned.
   * `in_Active`: temporarily inactive.

---

## 🛠️ 6. Maintenance Rules

1. `BusMaintenance`:
   * Links a `Bus` with a `MaintenanceService`.
   * Requires `status` to be `InProgress` or `Completed`.
2. When a maintenance record is created:
   * Sets `Bus.status` to `In_Maintenance`.
   * Assigns `Staff` to maintenance via `MaintenanceStaffAssignment`.
3. Upon completion (`BusMaintenance.status = 'Completed'`):
   * Sets `Bus.status` back to `Active`.
   * All related `Staff` statuses updated back to `Active`.

---

## 🚚 7. Driver & Assignment Rules

1. Each **BusDriver**:
   * Must have a unique `licenseNo` and valid `licenseExpiry`.
   * Only `status = 'active'` drivers can be assigned.
2. `DriverAssignment` can only be `Active` if:
   * Linked `Bus` and `BusDriver` are `Active`.
3. On assignment:
   * `BusDriver.status` may transition to `InAssignment` (by business logic).

---

## 🕑 8. Scheduling, Trips & Logs Rules

1. A **BusSchedule** is `Active` (or `Planned`) if:
   * Linked `Route` is `Active`.
2. Long trips (`>7 hours`) require at least **2 DriverAssignments** on the same schedule.
3. Actual stops are logged in `TripStopLog`.
[IDEA : when we some reason the driver assignment is become inactive , we dont directly trigger those Trigger update ticket.status to cancalled and make refund instead we search are they have a driverAssigment is currently dont have a busSchedule yet than we put the almost become inactive busSchedule for it else the update the ticket become cancelled      ]
---

## 🎟️ 9. Ticketing Rules

1. Tickets can only be created if:
   * `BusSchedule` is `Active`.
2. `Ticket.status` controls business flow:
   * `booked_extended` if extended to another `BusSchedule`.
   * `Cancelled_By_User` or `Cancelled_By_Company` marks it as void.
3. Extensions:
   * Only within 2 days before original schedule.
   * Must stay on the same `Route`.
   * Handled by linking to `extendedToID` with a new `BusSchedule`.

---

## 💰 10. Payment, Points & Membership Rules

1. `PaymentRecord` ties customer payments, refunds or extensions to their transactions.
2. `PointTransaction`:
   * Tracks earned or redeemed points with clear `source` (e.g. Ticket Purchase, Birthday Promo).
   * `pointBalance` on `Customer` must stay ≥ 0.

---

## ⚙️ 11. Indexing, Uniqueness & Data Consistency

1. All `ICPassportNo` (for `Customer` and `Staff`) and `Bus.plateNo`, `BusDriver.licenseNo` must be **unique**.
2. Composite PKs in `MaintenanceStaffAssignment` (`maintenanceID`, `staffID`) prevent duplicate staff on the same maintenance.
3. Timestamps (`createdAt`, `updatedAt`) are auto-managed for all tables.
4. Ensure all `ENUM` fields use allowed values exactly as defined.

---

## ✅ Data Safety Checks

* Always insert or update rows in proper order (reference tables first, e.g. `BusCompany`, `StaffRole`, `BusStation`).
* When testing, ensure no foreign key breaks occur (e.g. assigning `routeID` that does not exist).

---

## 📝 Final Notes

This documentation ensures all database test data and actual data comply with design constraints and maintain referential integrity — avoiding insert/update errors due to missing foreign keys, invalid enums, or duplicate unique fields.



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

**Ensure unique combination of**: `startPoint`, `endPoint`

#### `RouteStation`
Defines the order of [`BusPlatform`s](#busplaform) (that buses stop by) along a [`Route`](#route).

*Example:* for `routeID: 42`, the following records may exist:
- `{ routeID: 42, stopOrder: 1, platformID: 'P103' }`
- `{ routeID: 42, stopOrder: 2, platformID: 'P009' }`
- `{ routeID: 42, stopOrder: 3, platformID: 'P126' }`

which means that a bus travelling along route `42` will stop by platforms `P103`, `P009`, `P126` in that order.

**Ensure unique combination of**: 
- `routeID`, `stopOrder`
- `routeID`, `platformID`

*Note: Make sure there are two separate uniqueness checks, instead of
one uniqueness check for (`routeID`, `stopOrder`, `platformID`).*

### Bus fleet management
#### `Bus`
Includes license plates of buses.

#### `MaintenanceService`
Records types of maintenance services provided by the Bus Station, and their cost.

#### `BusMaintenance`
A log of what types of [maintenance services](#maintenanceservice) have been provided to which [buses](#bus). Attributes also include additional charges (if any) on top of the base cost specified in the [`MaintenanceService`](#maintenanceservice) table. 

**Ensure unique combination of:** `busID`, `serviceID`, `maintenanceDate`

#### `MaintenanceStaffAssignment`
Associative entity between [`BusMaintenance`](#busmaintenance) and [`Staff`](#staff). 
Records which staff (can be multiple) worked on a maintenance service.

### Schedule and operations
#### `BusSchedule`
Records planned arrival and departure times for each [route](#route). (These times may not reflect the actual time of arrival and departure.) 

#### `BusDriver`
A bus driver. Works for a certain [bus company](#buscompany).

#### `DriverListAssignment`
Each record is a combination of a [bus](#bus) and one/two [driver](#busdriver)s. Assigns one/two drivers to a bus for a specific duration of time (recorded by the attributes `assignedFrom` and `assignedTo`). [RouteDriverAssignmentList](#routedriverassignmentlist) references this table. 

**Ensure unique combination of**: `mainDriverID`, `supportDriverID`, `busID`, `assignedFrom`

#### `RouteDriverAssignmentList`
Each record is a combination of a [route](#route) and a [bus](#bus)-[driver(s)](#busdriver) assignment (see [`DriverListAssignment`](#driverlistassignment)). Assigns a bus and one/two drivers to a route, for a specific duration of time (recorded by the attributes `effectiveFrom` and `effectiveTo`).

Since there can be one or two drivers, `mainDriverID` is non-nullable i.e. mandatory, while `supportDriverID` is nullable i.e. optional.

**Ensure unique combination of**: `routeID`, `assignmentID`, `effectiveFrom`

#### `TripStopLog`
A log of when a bus departs from a designated [route](#route)'s origin and arrives at the destination. Each record references a certain [bus schedule](#busschedule). Records *actual* arrival and departure time as opposed to the *planned* arrival and departure times recorded by [`BusSchedule`](#busschedule))

### Payment system
#### `PaymentRecord`
Records customer payments, including method, amount, loyalty points used, and status for various transaction types (e.g., ticket, membership, refund).

#### `PointTransaction`
Tracks loyalty point activities for customers, such as earning, redemption, and refunds, often linked to payment records.

### Ticketing system
#### `Ticket`
Represents a bus booking by a customer for a specific bus schedule, with pricing, seat info, and support for cancellation (which may/may not include refund) and extension.

### Shop and Rental Management
<!-- #### `Tenant`
Stores information about individuals or companies renting shop lots in bus stations, including contact and status details. -->

#### `Shop`
Defines a shop lot at a bus station, linking it to tenants, with details on rental fees, contract periods, and occupancy status.

#### `RentalCollection`
A log of which [staff](#staff) collected the rent for which [shop](#shop).

<!-- #### `ShopPayment`
Captures rental-related payments from tenants for shops, including payment type (e.g., rental, deposit), method, and status. -->

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
