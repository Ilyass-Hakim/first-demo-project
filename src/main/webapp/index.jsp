<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Simple JSP Page</title>
</head>
<body>
    <h1>Hello from JSP!</h1>
    
    <%
        String message = "Welcome to my simple JSP page";
        int number = 42;
    %>
    
    <p><%= message %></p>
    <p>Today's lucky number is: <%= number %></p>
    <p>Current time: <%= new java.util.Date() %></p>
    
    <form method="post">
        <input type="text" name="username" placeholder="Enter your name">
        <input type="submit" value="Submit">
    </form>
    
    <%
        String username = request.getParameter("username");
        if (username != null && !username.isEmpty()) {
    %>
        <h2>Hello, <%= username %>!</h2>
    <%
        }
    %>
    
</body>
</html>
