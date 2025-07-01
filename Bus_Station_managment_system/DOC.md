## Assumptions
1. Our bus station serves long-trip buses. This assumption is made because we interact with many different bus companies, which isn't how it typically works for area buses like RapidKL where all buses belong to one company.

## Tables
> **Note**: This section provides explanation for tables whose purpose may not be immediately obvious. It does not intend to document the purpose of all tables.

**`Route`**: Records bus routes: from where to where? *Does not record schedule* -- that's handled by `BusSchedule`. 

**`BusSchedule`**: Records planned arrival and departure times for each route. (These times may not reflect the actual time of arrival and departure.) 

**`RouteStation`**: Defines the order of platforms (that buses stop by) along a route.

*Example:* for `routeID: R001`, the following records may exist:
- `{ routeID: 'R001', stopOrder: 1, platformID: 'P103' }`
- `{ routeID: 'R001', stopOrder: 2, platformID: 'P009' }`
- `{ routeID: 'R001', stopOrder: 3, platformID: 'P126' }`

which means that a bus travelling along route `R001` will stop by platforms `P103`, `P009`, `P126` in that order.

**`TripStopLog`**: A log of when a bus departs from a designated route's origin and when it arrives at the designated destination. 

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
