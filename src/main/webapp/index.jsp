<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*"%>
<%@ page import="java.sql.*"%>
<!DOCTYPE html>
<html>
<head>
    <title>TaskFlow - Vulnerable Demo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
<%
    // ============================
    // 1. Hardcoded Secrets (Gitleaks)
    // ============================
    String secretApiKey = "AKIA1234567890ABCD12"; // AWS key style
    String jwtSecret = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fake";
    String slackToken = "xoxb-1234567890-abcdefgh";
    String dbPassword = "P@ssw0rd123";

    // ============================
    // 2. Vulnerable SQL (SQL Injection)
    // ============================
    String userInput = request.getParameter("user");
    String unsafeQuery = "SELECT * FROM users WHERE username = '" + userInput + "'";
    
    // ============================
    // 3. Reflected XSS
    // ============================
    String comment = request.getParameter("comment");

    // ============================
    // 4. Insecure Deserialization
    // ============================
    Object obj = request.getSession().getAttribute("userObject"); 

    // ============================
    // 5. Weak password
    // ============================
    String weakPassword = "123456";

    // ============================
    // 6. Debug info exposure
    // ============================
    String sessionId = session.getId();

%>

<h1>TaskFlow - Full Vulnerable Demo</h1>

<h2>Secrets (Hardcoded)</h2>
<p>AWS Key: <%= secretApiKey %></p>
<p>JWT Secret: <%= jwtSecret %></p>
<p>Slack Token: <%= slackToken %></p>
<p>DB Password: <%= dbPassword %></p>

<h2>SQL Injection Example</h2>
<p>Query: <%= unsafeQuery %></p>

<h2>Reflected XSS Example</h2>
<p>User Comment: <%= comment %></p>

<h2>Weak Password</h2>
<p>Password: <%= weakPassword %></p>

<h2>Insecure File Upload</h2>
<form method="post" enctype="multipart/form-data">
    <input type="file" name="uploadFile">
    <button type="submit">Upload</button>
</form>

<h2>Debug Info</h2>
<p>Session ID: <%= sessionId %></p>

<h2>Tasks</h2>
<%
    List<Map<String, String>> tasks = new ArrayList<>();
    Map<String, String> t1 = new HashMap<>(); t1.put("title","Deploy production release"); t1.put("priority","high"); tasks.add(t1);
    Map<String, String> t2 = new HashMap<>(); t2.put("title","Review code"); t2.put("priority","medium"); tasks.add(t2);
    for(Map<String,String> task : tasks) {
%>
    <div><strong><%= task.get("title") %></strong> - Priority: <%= task.get("priority") %></div>
<%
    }
%>

<%
    // Insecure headers
    response.setHeader("X-Frame-Options","ALLOWALL");
%>

</body>
</html>
