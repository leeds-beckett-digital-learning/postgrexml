# postgrexml
Use XML to fetch XML from Postgresql tables.

## Use Case
PostgreSQL has a number of functions that make it possible to ouput data in XML format.
However, if you want to nest multiple tables to produce a complex tree structure the 
necessary SQL is very hard to construct.

Wouldn't it be nice if instead of composing SQL you could create an XML file that
models what you want?

That's what this project is about. It consists of an XSL transform that can take
a model XML file and output complex SQL.

## How to Use
To go from specification XML file to data in XML format is a simple two step process;

1. Transform the specification file using an XSLT 1.0 compliant tool and specifying the transform `xmltosql.xsl` from this project.
Choose your own output file name, probably with `.sql` file extension.
2. Execute the `.sql` file using any PostgreSQL compatible client software. The result will be a single
row with a single field and that field will contain the XML output.

That's all!

The author's intention is to use this transform within a Java application named Bubblesucker. So, this 
project is set up with a gradle build file so the XSL transform can be packaged up in a jar file, published
to Maven and thus can be easily drawn down into Java projects. You can incorporate this file into your
Java project using Maven or simply download the `.xsl` file.

The [project page on maven central](https://central.sonatype.com/artifact/io.github.leeds-beckett-digital-learning/postgrexml) lists 
ways to include this project in your Maven, Gradle etc. project.

## Example
Better to see an example first and read a specification later...

```
<?xml version="1.0" encoding="UTF-8"?>
<course_main thing="whatsit" doodah="bonzo" timestamp="sql;current_timestamp(0)" xmlns:pgxml="http://leedsbeckett.ac.uk/postgrexml"> 
  <cm_row pgxml:from="public.course_main" pgxml:where="pk1 IN (166666, 188888)" pk1="sql;public.course_main.pk1" data_src_pk1="sql;public.course_main.data_src_pk1">
    <course_name><pgxml:field bbls:expression="public.course_main.course_name"/></course_name>
    <dtcreated><pgxml:field bbls:expression="public.course_main.dtcreated"/></dtcreated>
    <dtmodified><pgxml:field bbls:expression="public.course_main.dtmodified"/></dtmodified>
    <course_desc><pgxml:field bbls:expression="public.course_main.course_desc"/></course_desc>
    <course_users> 
      <cu_row pgxml:from="public.course_users" pgxml:where="public.course_main.pk1 = public.course_users.crsmain_pk1" pk1="sql;public.course_users.pk1"> 
        <user pgxml:from="public.users" pgxml:where="public.course_users.users_pk1 = public.users.pk1"> 
          <lastname><pgxml:field pgxml:expression="public.users.lastname"/></lastname>
          <firstname><pgxml:field pgxml:expression="public.users.firstname"/></firstname>
          <student_id><pgxml:field pgxml:expression="public.users.student_id"/></student_id>
        </user>
      </cu_row>
    </course_users>
  </cm_row>
</course_main>
```
This is transformed to a single SQL SELECT query which, when executed might produce something like this:
```
<?xml version="1.0" encoding="UTF-8"?>
<course_main thing="whatsit" doodah="bonzo" timestamp="2025-10-28T11:58:27+00:00"> 
  <cm_row pk1="166666" data_src_pk1="7">
    <course_name>HEAL444 - Environmental Science</course_name>
    <dtcreated>2022-04-26T16:24:53.224</dtcreated>
    <dtmodified>2022-10-10T17:10:34.857</dtmodified>
    <course_desc/>
    <course_users> 
      <cu_row pk1="5955555"> 
        <user> 
          <lastname>Smith</lastname>
          <firstname>MJohn</firstname>
          <student_id>336336336</student_id>
        </user>
      </cu_row> 
      <cu_row pk1="6077777"> 
        <user> 
          <lastname>Jones</lastname>
          <firstname>Jane</firstname>
          <student_id>33651515</student_id>
        </user>
      </cu_row> 
      <cu_row pk1="60688888"> 
        <user> 
          <lastname>Kahn</lastname>
          <firstname>Rashid</firstname>
          <student_id>33622222</student_id>
        </user>
      </cu_row> 
    </course_users>
  </cm_row> 
  <cm_row pk1="188888" data_src_pk1="7">
    <course_name>BAH Housing Studies</course_name>
    <dtcreated>2025-10-24T16:02:02.091</dtcreated>
    <dtmodified>2025-10-24T16:02:04.455</dtmodified>
    <course_desc>This group will allow easier communication via announcements...</course_desc>
    <course_users>
      <cu_row pk1="5955955"> 
        <user> 
          <lastname>Gregory</lastname>
          <firstname>Simon.</firstname>
          <student_id>33622222</student_id>
        </user>
      </cu_row> 
      <cu_row pk1="5953333"> 
        <user> 
          <lastname>Wilson</lastname>
          <firstname>Mary</firstname>
          <student_id>33600000</student_id>
        </user>
      </cu_row>
    </course_users>
  </cm_row>
</course_main>
```
## How to Design a Specification File
Every element and attribute that is not placed into a namespace and every text node will be literally reproduced in the result of the query.
There are two ways to expand the output using data from the database;
### Repeating Elements
An element can be made to repeat by adding two attributes - `pgxml:from` identifies the table from which records will be fetched
and `pgxml:where` is used to provide an expression that selects specific records from the table.  The XML element will be repeated
once for each result found by the query. The text node that immediately precedes the element, if there is one, will also be repeated
to keep the layout tidy.
### Inserting Data in Text Nodes
An element `<pgxml:field pgxml:expression="..."/>` will be replaced by data by evaluating the expression attribute. This is likely to
be in the context of a repeated row and the expression will reference a field in the selected table.
### Dynamic Attributes
If the value of an attribute has the prefix `sql;` then the remainder of the attribute value will be used as an SQL expression
and the result of the expression will be output as the value of the attribute in the output file. 
For example the attribute `timestamp="sql;current_timestamp(0)"` is expanded in
the final XML output as `timestamp="2025-10-28T11:58:27+00:00"`.  If the dynamic attribute is in the context of a repeated element
the expression will often be the name of a field, e.g. `pk1="sql;public.course_main.pk1"` on a repeating row will
set the value of the attribute `pk1` to the value of the `pk1` field corresponding to each record found.

## The Specification
### Namespace
The namespace is `http://leedsbeckett.ac.uk/postgrexml`. This ensures that the user is free to use any element names and
attribute names they like without fear of clashing with *special* elements and attributes in the present specification or
a later version.
### Attribute pgxml:from
This attribute is used on an element to indicate a database table will be used as a source of data for the element and
its descendents.  It must always be accompanied by the `pgxml:where` attribute.
### Attribute pgxml:where
This attribute accompanies the `pgxml:from` attribute and provides the `WHERE` clause for an SQL query that will select
data for use in this element and its descendents.
### Element pgxml:field
This element will result in a text node in the output containing data from the database.
### Attribute pgxml:expression
This attribute is added to the pgxml:field element and provides an SQL expression that will be evaluated. The
result of the expression, in the context where it appears, will be inserted into a text node.
### Attribute values starting with 'sql;'
Like the `pgxml:field` element this inserts data from the database based on an expression. However, instead of
inserting into a text node this inserts into the value of attribute.

