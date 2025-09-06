<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.sql.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>TaskFlow - Vulnerable Task Manager</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; background:#f0f0f0; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 15px; }
        .task-item { padding: 15px; margin-bottom: 10px; border-left: 5px solid; }
        .task-high { border-color: red; }
        .task-medium { border-color: orange; }
        .task-low { border-color: green; }
    </style>
</head>
<body>
<%
    // ============================
    // 1. Hardcoded Secrets (Gitleaks)
    // ============================
    String secretApiKey = "AKIAIOSFODNN7EXAMPLE";
    String jwtSecret = "superSecretJWTKey12345";
    String dbPassword = "P@ssw0rd123";

    // ============================
    // 2. Vulnerable SQL (SQL Injection)
    // ============================
    String userInput = request.getParameter("user");
    String unsafeQuery = "SELECT * FROM users WHERE username = '" + userInput + "'"; // SQLi

    // ============================
    // 3. Insecure Reflection / XSS
    // ============================
    String reflectedInput = request.getParameter("comment"); // directly reflected to page

    // ============================
    // 4. Insecure Deserialization (just example)
    // ============================
    // Simulate reading an object from user input without validation
    Object obj = request.getSession().getAttribute("userObject"); // could be exploited if attacker sets malicious object

    // ============================
    // 5. Weak Password Example
    // ============================
    String weakPassword = "123456"; // SonarQube will flag

    // ============================
    // 6. Simulated Tasks (Insecure Storage)
    // ============================
    List<Map<String, String>> tasks = new ArrayList<>();
    Map<String, String> t1 = new HashMap<>(); t1.put("title", "Deploy prod release"); t1.put("priority", "high"); tasks.add(t1);
    Map<String, String> t2 = new HashMap<>(); t2.put("title", "Review code"); t2.put("priority", "medium"); tasks.add(t2);
%>

<div class="container">
    <h1>TaskFlow - Vulnerable Demo</h1>

    <h2>Hardcoded Secrets</h2>
    <p>Secret API Key: <%= secretApiKey %></p>
    <p>JWT Secret: <%= jwtSecret %></p>
    <p>DB Password: <%= dbPassword %></p>

    <h2>Unsafe SQL Query (SQL Injection)</h2>
    <p><%= unsafeQuery %></p>

    <h2>Reflected User Input (XSS)</h2>
    <p>User Comment: <%= reflectedInput %></p>

    <h2>Weak Password Example</h2>
    <p>Password: <%= weakPassword %></p>

    <h2>Tasks</h2>
    <% for (Map<String, String> task : tasks) { %>
        <div class="task-item task-<%= task.get("priority") %>">
            <strong><%= task.get("title") %></strong> - Priority: <%= task.get("priority") %>
        </div>
    <% } %>

    <h2>Insecure File Upload Example</h2>
    <form method="post" enctype="multipart/form-data">
        <input type="file" name="uploadFile">
        <button type="submit">Upload</button>
    </form>

    <h2>Insecure HTTP Header (No HSTS)</h2>
    <% response.setHeader("X-Frame-Options", "ALLOWALL"); %>

    <h2>Debug Info Exposure</h2>
    <p>Session ID: <%= session.getId() %></p>
</div>
</body>
</html>
