# Comprehensive Drasi Guide

## Table of Contents
1. [Introduction to Drasi](#introduction-to-drasi)
2. [Core Concepts](#core-concepts)
   - [Sources](#sources)
   - [Continuous Queries](#continuous-queries)
   - [Reactions](#reactions)
   - [Query Containers](#query-containers)
   - [Middleware](#middleware)
3. [Installation and CLI](#installation-and-cli)
4. [Query Language](#query-language)
5. [Solution Design Patterns](#solution-design-patterns)
6. [Practical Examples](#practical-examples)
7. [References and Further Reading](#references-and-further-reading)

## Introduction to Drasi

Drasi is a Data Change Processing platform that makes it easier to build dynamic solutions that detect and react to data changes in **existing** databases and software systems. Drasi goes beyond simple change detection - it uses a query-based approach with rich graph queries to express sophisticated rules about the changes you want to detect.

### Key Benefits

- **No Code Required**: Write declarative queries instead of complex stream processing code
- **Works with Existing Systems**: No need to modify existing databases or applications
- **Rich Query Language**: Uses Cypher to express complex relationships and conditions
- **Real-time Reactions**: Instantly react to changes as they occur
- **Multiple Data Sources**: Query across different databases as a unified graph

### Core Components Overview

Drasi is built around three simple components that work together:

1. **Sources**: Connect to existing systems and monitor them for changes
2. **Continuous Queries**: Define what changes to detect using Cypher queries
3. **Reactions**: Take action when query results change

## Core Concepts

### Sources

Sources provide connectivity to systems that Drasi observes for changes. They perform three key functions:

1. Process change logs/feeds from source systems
2. Translate data into a consistent property graph model
3. Provide query capabilities for initialization

#### Available Sources

- **PostgreSQL** - Monitors PostgreSQL databases for changes
- **MySQL** - Tracks changes in MySQL databases  
- **Microsoft SQL Server** - Connects to SQL Server instances
- **Azure Cosmos DB Gremlin API** - Works with graph databases
- **Kubernetes** - Monitors Kubernetes resources
- **Microsoft Dataverse** - Integrates with Dataverse entities
- **Azure Event Hubs** - Processes event streams

#### Creating a Source

Sources are defined using YAML configuration files:

```yaml
apiVersion: v1
kind: Source
name: my-database
spec:
  kind: PostgreSQL
  properties:
    host: postgres.example.com
    port: 5432
    user: myuser
    password: 
      kind: Secret
      name: pg-creds
      key: password
    database: mydb
    ssl: false
    tables:
      - public.customers
      - public.orders
```

For detailed configuration of each source type, refer to `./.claude/drasi/sources.md`.

### Continuous Queries

Continuous Queries are the heart of Drasi. Unlike traditional queries that run once and return results, Continuous Queries:

- Run continuously until stopped
- Maintain perpetually accurate results
- Detect exactly what changed (added, updated, deleted)
- Distribute change notifications to subscribed Reactions

#### Query Features

- Written in Cypher query language
- Can span multiple Sources
- Support synthetic relationships between disconnected data
- Include temporal functions for time-based conditions
- Support aggregations and transformations

#### Example: Employee Risk Detection

```yaml
apiVersion: v1
kind: ContinuousQuery
name: at-risk-employees
spec:
  sources:    
    subscriptions:
      - id: hr-database
      - id: risk-management
  query: > 
    MATCH
      (e:Employee)-[:LOCATED_IN]->(:Building)-[:LOCATED_IN]->(r:Region),
      (i:Incident {type:'environmental'})-[:OCCURS_IN]->(r:Region) 
    WHERE
      i.severity IN ['critical', 'extreme'] AND i.endTimeMs IS NULL
    RETURN 
      e.name AS EmployeeName,
      e.email AS EmployeeEmail,
      r.name AS RegionName,
      i.severity AS IncidentSeverity
```

#### Synthetic Relationships

Drasi can create relationships between data from different sources:

```yaml
joins:
  - id: VEHICLE_TO_DRIVER
    keys:
      - label: Vehicle
        property: plate
      - label: Driver
        property: plate
```

For complete query language documentation, see [Query Language](#query-language) section below.

### Reactions

Reactions process the stream of changes from Continuous Queries and take action. Available reactions include:

#### Built-in Reactions

- **SignalR** - Push changes to web applications in real-time
- **Azure Event Grid** - Forward changes to Azure Event Grid
- **Debug** - Inspect query results during development
- **Gremlin** - Execute commands against graph databases
- **StoredProc** - Call SQL stored procedures
- **AWS EventBridge** - Publish to AWS Event Bus
- **Sync Dapr State Store** - Maintain materialized views
- **Dataverse** - Update Microsoft Dataverse entities

#### Creating a Reaction

```yaml
apiVersion: v1
kind: Reaction
name: notify-managers
spec:
  kind: SignalR
  queries:
    at-risk-employees:
  endpoint:
    gateway: 8080
```

For detailed reaction configurations, refer to `./.claude/drasi/reactions.md`.

### Query Containers

Query Containers host Continuous Queries and can be scaled independently. The default container is created during installation, but you can create custom containers for:

- Resource isolation
- Performance optimization
- Different storage profiles

### Middleware

Middleware preprocesses incoming changes before they reach queries. Available middleware includes:

#### Unwind
Extracts nested arrays into top-level graph nodes:

```yaml
middleware:
  - name: extract-items
    kind: unwind
    Order:
      - selector: $.items[*]
        label: OrderItem
        key: $.itemId
        relation: CONTAINS
```

#### Map
Transforms changes from one type to another:

```yaml
middleware:
  - kind: map
    name: latest-reading
    SensorLog:
      insert:
        - selector: $
          op: Update
          label: Sensor
          id: $.sensorId
          properties:
            currentValue: $.value
```

#### Promote
Copies nested values to top-level properties:

```yaml
middleware:
  - name: promote_user_data
    kind: promote
    config:
      mappings:
        - path: "$.user.id"
          target_name: "userId"
```

#### ParseJson
Parses JSON strings into structured objects:

```yaml
middleware:
  - name: parse_event
    kind: parse_json
    config:
      target_property: "raw_json"
      output_property: "parsed_data"
```

#### Decoder
Decodes encoded strings (Base64, Hex, URL, etc.):

```yaml
middleware:
  - name: decode_payload
    kind: decoder
    config:
      encoding_type: "base64"
      target_property: "encoded_data"
      output_property: "decoded_data"
```

For complete middleware documentation, refer to `./.claude/drasi/middleware.md`.

## Installation and CLI

### Installation

Install the Drasi CLI:

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/drasi-project/drasi-platform/main/cli/installers/install-drasi-cli.sh | /bin/bash

# Windows PowerShell
iwr -useb "https://raw.githubusercontent.com/drasi-project/drasi-platform/main/cli/installers/install-drasi-cli.ps1" | iex
```

Install Drasi on Kubernetes:

```bash
drasi init
```

With observability:

```bash
drasi init --observability-level full
```

### Essential CLI Commands

#### Resource Management

```bash
# Apply resources
drasi apply -f resource.yaml

# List resources
drasi list source
drasi list query
drasi list reaction

# Describe a resource
drasi describe query my-query

# Delete resources
drasi delete source my-source

# Wait for resources to be ready
drasi wait -f resource.yaml -t 120
```

#### Query Monitoring

```bash
# Watch query results in real-time
drasi watch my-query
```

#### Environment Management

```bash
# List environments
drasi env all

# Switch environment
drasi env use production

# Add current k8s context
drasi env kube
```

#### Secrets Management

```bash
# Set a secret
drasi secret set MyDatabase Password mypassword

# Delete a secret
drasi secret delete MyDatabase Password
```

For complete CLI documentation, refer to `./.claude/drasi/command-line-interface.md`.

## Query Language

Drasi uses a subset of Cypher with custom extensions for change detection.

### Supported Cypher Features

- **MATCH** clause with node and relation patterns
- **WHERE** clause with complex conditions
- **WITH** clause for intermediate processing
- **RETURN** clause with aliases
- **Aggregations**: count, sum, avg, min, max
- **Functions**: String, numeric, temporal, list operations

### Drasi-Specific Functions

#### Temporal Functions

```cypher
// Get when an element changed
drasi.changeDateTime(element)

// Evaluate condition at future time
drasi.trueLater(condition, timestamp)

// Check if condition remains true for duration
drasi.trueFor(condition, duration)

// Check if condition stays true until timestamp
drasi.trueUntil(condition, timestamp)
```

#### List Functions

```cypher
// Get min/max from list
drasi.listMin([1, 2, 3])  // Returns 1
drasi.listMax([1, 2, 3])  // Returns 3
```

#### Statistical Functions

```cypher
// Calculate linear gradient for predictions
drasi.linearGradient(x_values, y_values)
```

### Example Queries

#### Detect Delayed Orders

```cypher
MATCH (o:Order)-[:ASSIGNED_TO]->(d:Driver)
WHERE 
  o.status != 'ready' AND
  drasi.trueFor(d.location = 'waiting', duration({minutes: 10}))
RETURN 
  o.id AS OrderId,
  d.name AS DriverName,
  drasi.changeDateTime(d) AS WaitingSince
```

#### Monitor System Health

```cypher
MATCH (s:Service)
WITH s, avg(s.responseTime) AS avgResponse
WHERE avgResponse > 1000
RETURN 
  s.name AS ServiceName,
  avgResponse AS AverageResponseTime
```

For complete query language reference, see `./.claude/drasi/query-language.md`.

## Solution Design Patterns

Drasi supports three main approaches to change detection:

### 1. Observing Changes

Simple detection of create, update, delete operations:

```yaml
query: > 
  MATCH (c:Customer)
  WHERE c.status = 'new'
  RETURN c.id, c.name, c.email
```

### 2. Observing Conditions

Detect when specific conditions are met:

```yaml
query: >
  MATCH (o:Order)
  WHERE 
    o.total > 10000 AND 
    o.status = 'pending_approval'
  RETURN o.id, o.total, o.customer
```

### 3. Observing Collections

Maintain dynamic collections with complex criteria:

```yaml
query: >
  MATCH 
    (o:Order {status: 'ready'})-[:PICKUP_BY]->(v:Vehicle),
    (v)-[:LOCATED_AT]->(z:Zone {type: 'pickup'})
  RETURN 
    o.id AS OrderId,
    v.plate AS VehiclePlate,
    z.name AS ZoneName
```

For detailed solution design guidance, refer to `./.claude/drasi/solution-design.md`.

## Practical Examples

### Building Comfort Dashboard

Monitor building sensor data and calculate comfort levels:

```yaml
query: >
  MATCH
    (r:Room)-[:PART_OF]->(f:Floor)-[:PART_OF]->(b:Building)
  WITH
    r, f, b,
    floor(50 + (r.temperature - 72) + (r.humidity - 42) + 
      CASE WHEN r.co2 > 500 THEN (r.co2 - 500) / 25 ELSE 0 END
    ) AS ComfortLevel
  WHERE ComfortLevel < 40 OR ComfortLevel > 50
  RETURN
    b.name AS Building,
    f.name AS Floor,
    r.name AS Room,
    ComfortLevel
```

Full tutorial: `./.claude/drasi/tutorial-building-comfort.md`

### Curbside Pickup System

Match ready orders with waiting vehicles across multiple databases:

```yaml
# Join across PostgreSQL and MySQL sources
joins:
  - id: PICKUP_BY
    keys:
      - label: Order
        property: vehiclePlate
      - label: Vehicle
        property: plate

query: >
  MATCH (o:Order)-[:PICKUP_BY]->(v:Vehicle)
  WHERE 
    o.status = 'ready' AND 
    v.location = 'curbside'
  RETURN o.id, v.plate, o.customerName
```

Full tutorial: `./.claude/drasi/tutorial-curbside-pickup.md`

### Risky Container Detection

Monitor Kubernetes for containers with security risks:

```yaml
# Using middleware to extract container data
middleware:
  - kind: unwind
    name: extract-containers
    Pod:
      - selector: $.status.containerStatuses[*]
        label: Container
        key: $.containerID
        relation: OWNS

query: >
  MATCH 
    (p:Pod)-[:OWNS]->(c:Container)-[:HAS_IMAGE]->(i:RiskyImage)
  RETURN
    p.name AS PodName,
    c.image AS Image,
    i.reason AS RiskReason
```

Full tutorial: `./.claude/drasi/tutorial-risky-containers.md`

## References and Further Reading

### Original Documentation Files

For more detailed information on specific topics, refer to the original documentation files:

- **Overview and Concepts**: `./.claude/drasi/overview.md` - Why Drasi exists and core concepts
- **Command Line Interface**: `./.claude/drasi/command-line-interface.md` - Complete CLI reference
- **Sources**: `./.claude/drasi/sources.md` - Detailed source configurations
- **Continuous Queries**: `./.claude/drasi/continuous-queries.md` - Query configuration and features
- **Reactions**: `./.claude/drasi/reactions.md` - Available reactions and configurations
- **Query Language**: `./.claude/drasi/query-language.md` - Cypher syntax and Drasi functions
- **Middleware**: `./.claude/drasi/middleware.md` - Preprocessing capabilities
- **Solution Design**: `./.claude/drasi/solution-design.md` - Architecture patterns

### Tutorials

Complete step-by-step tutorials with code:

1. **Building Comfort**: `./.claude/drasi/tutorial-building-comfort.md`
   - Single data source integration
   - Real-time dashboard with SignalR
   - Comfort level calculations

2. **Curbside Pickup**: `./.claude/drasi/tutorial-curbside-pickup.md`
   - Multiple data source integration
   - Temporal queries for delays
   - Cross-database joins

3. **Risky Containers**: `./.claude/drasi/tutorial-risky-containers.md`
   - Kubernetes integration
   - Security monitoring
   - Middleware usage

### Key Takeaways for Agents

When working with Drasi:

1. **Start Simple**: Begin with basic change detection before moving to complex conditions
2. **Use Synthetic Joins**: Connect data across sources using the `joins` configuration
3. **Leverage Middleware**: Transform data before it reaches queries for cleaner logic
4. **Think in Graphs**: Model your data as nodes and relationships, even from relational sources
5. **Test with Debug Reaction**: Use the Debug reaction to inspect query results during development
6. **Monitor Performance**: Use appropriate storage profiles for large-scale deployments
7. **Incremental Development**: Start with one source and query, then expand

### Common Patterns

1. **Real-time Dashboards**: Source → Query → SignalR Reaction → Web UI
2. **Event Processing**: Source → Query → Event Grid/EventBridge → Serverless Functions
3. **Database Sync**: Source → Query → StoredProc/Gremlin Reaction → Target Database
4. **Alerting**: Source → Query with conditions → Reaction → Notification System

Remember: Drasi excels at detecting complex changes across multiple systems without requiring code changes to existing applications.