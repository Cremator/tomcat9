# Tomcat XML Environment Configurator

A lightweight Bash utility for dynamically modifying Apache Tomcat XML configuration files using Docker environment variables.

The script allows XML configuration changes to be declared entirely through environment variables, making Tomcat images reusable and configuration portable.

## Features

- Configure Tomcat XML files through environment variables
- XML-aware updates using xmlstarlet
- Automatic XML namespace detection
- Update existing attributes
- Create missing XML nodes
- Select nodes using element attributes
- Docker-friendly and idempotent

## Requirements

The container requires:

- Bash
- xmlstarlet
- Tomcat

## Configuration Format

All variables must start with:

```text
TOMCATXML__
```

Format:

```text
TOMCATXML__<xml-file>__<xpath path>__<attribute>
```

The environment variable value becomes the XML attribute value.

## File Path Syntax

The base directory is:

```text
/usr/local/tomcat
```

Because Docker environment variables cannot contain `/`, paths use `:`.

Example:

```text
conf:context.xml
```

maps to:

```text
/usr/local/tomcat/conf/context.xml
```

## XML Path Syntax

Elements are separated using:

```text
__
```

Example:

```text
Context__JarScanner__scanManifest
```

represents:

```xml
<Context>
    <JarScanner scanManifest="..."/>
</Context>
```

The final section is always treated as the attribute name.

## Selecting Existing Nodes

Nodes can be selected using attributes:

```text
Element[attribute:value]
```

Example:

```yaml
TOMCATXML__conf:tomcat-users.xml__tomcat-users__user[username:admin]__roles: manager-gui
```

Updates:

```xml
<user username="admin" roles="manager-gui"/>
```

## Missing Node Creation

If a requested node does not exist, it is created automatically.

Example:

```yaml
TOMCATXML__conf:context.xml__Context__Resource[name:ApplicationDS]__username: dbUser
```

Creates:

```xml
<Context>
    <Resource name="ApplicationDS" username="dbUser"/>
</Context>
```

## XML Namespace Support

Namespaces are detected automatically.

The script internally configures xmlstarlet namespace handling, so no extra configuration is required.

## Docker Compose Example

```yaml
environment:
  TOMCATXML__conf:tomcat-users.xml__tomcat-users__user[username:admin]__password: passw0rd
  TOMCATXML__conf:context.xml__Context__JarScanner__scanManifest: false
  TOMCATXML__conf:context.xml__Context__Resource[name:ApplicationDS]__url: jdbc:oracle:thin:@10.0.1.1:1521:DB
```

## Special Characters

Pipe characters and values containing `=` are supported:

```text
buckets=.01|.05|.1|1|10
```

### Single quotes

Single quotes inside XPath selector values are not supported because XPath escaping becomes ambiguous.

## Startup Process

1. Scan environment variables.
2. Select variables beginning with `TOMCATXML__`.
3. Parse XML file, XPath path and attribute.
4. Detect XML namespace.
5. Create missing nodes.
6. Update or create attributes.

## Design Goals

- Immutable Tomcat images
- Environment-driven configuration
- Docker and Kubernetes compatibility
- No manual XML templates
- Safe XML modifications through xmlstarlet

## THIS README IS AI GENERATED