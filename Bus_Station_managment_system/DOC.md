## Some terminology before we begin
The **System** refers to the Bus Station Management System, the main character of this repository.

The **Bus Station** refers to the bus station company that the System is made for.


## Assumptions
1. The Bus Station serves long-trip buses. This assumption is made because it interacts with many different bus companies, which isn't how it typically works for area buses like RapidKL where all buses belong to one company.
2. All `BusDriver`s must hold PSV license, as that's the mandatory license for bus drivers.

## Business rules
1. `BusDriver.salary` and `Staff.salary` must be at least `1500`. (Minimum wage in Malaysia)
4. `Payment.pointsApplied` cannot be more than the corresponding `Customer` record's `pointBalance`.
5. 100 points = RM1. Points can only be used to purchase tickets or items from shops in the Bus Station.
2. Puchase of a ticket can be cancelled **at least 2 days in advance** with 70% refund. Otherwise, no refund will be given.
    - If loyalty points were used, 70% of the cash portion will be refunded in cash, and 70% of the loyalty points will be refunded as loyalty points.
    - SQL logic flow:
        - First, retrieve the original `Payment` record to get `cashAmount` (cash portion of the transaction) and `pointsApplied` (point value of the transaction). Calculate the cash refund as `0.7 * cashAmount` and the point refund as `0.7 * pointsApplied`. 
        - Create a new `Payment` record with `type` = `'refund'` that shows the negative cash amount and points being returned. 
        - Simultaneously, create a `PointTransaction` record that shows the points being added back to the customer's balance.
        - Update the customer's `Customer` record so that its `pointBalance` shows the latest balance.
        > **Note:** Changes to point balance are reflected by updating both `PointTransaction` and `Customer`. The two updates MUST always be done in *one atomic unit* **to ensure integrity**. Perhaps a function (or is it called procedure?) can be written to achieve this. 

3. A ticket can only be extended (same route, later time/date) **at least 2 days in advance** at current ticket price with an additional charge of RM5. The same ticket may only be extended **once**.


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
