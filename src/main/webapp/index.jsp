<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.Date" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Simple JSP Example</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .info-box {
            background-color: #e8f4f8;
            padding: 15px;
            border-left: 4px solid #2196F3;
            margin: 20px 0;
        }
        .user-form {
            margin-top: 20px;
        }
        input[type="text"] {
            padding: 8px;
            margin: 5px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        input[type="submit"] {
            padding: 8px 16px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        input[type="submit"]:hover {
            background-color: #45a049;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to My JSP Page</h1>
        
        <!-- JSP Scriptlet for server-side Java code -->
        <%
            // Get current date and time
            Date currentDate = new Date();
            String userName = request.getParameter("name");
            int visitCount = 1;
            
            // Check if session exists and get visit count
            if (session.getAttribute("visitCount") != null) {
                visitCount = (Integer) session.getAttribute("visitCount") + 1;
            }
            session.setAttribute("visitCount", visitCount);
        %>
        
        <div class="info-box">
            <h3>Server Information</h3>
            <p><strong>Current Date & Time:</strong> <%= currentDate %></p>
            <p><strong>Your Session ID:</strong> <%= session.getId() %></p>
            <p><strong>Visit Count:</strong> <%= visitCount %></p>
            <p><strong>Server Info:</strong> <%= application.getServerInfo() %></p>
        </div>
        
        <!-- Display personalized greeting if name is provided -->
        <% if (userName != null && !userName.trim().isEmpty()) { %>
            <div class="info-box">
                <h3>Hello, <%= userName %>!</h3>
                <p>Thank you for visiting our JSP page. We hope you find it helpful!</p>
            </div>
        <% } %>
        
        <!-- Simple form for user interaction -->
        <div class="user-form">
            <h3>Enter Your Name</h3>
            <form method="post" action="">
                <input type="text" name="name" placeholder="Your name here..." 
                       value="<%= userName != null ? userName : "" %>">
                <input type="submit" value="Submit">
            </form>
        </div>
        
        <!-- JSP Expression for dynamic content -->
        <div class="info-box">
            <h3>Dynamic Content</h3>
            <p>This page was generated at: <strong><%= new Date() %></strong></p>
            <p>Random number: <strong><%= Math.round(Math.random() * 100) %></strong></p>
        </div>
        
        <!-- Using JSP Declaration for methods -->
        <%!
            // JSP Declaration - defines methods and variables
            public String getWelcomeMessage() {
                return "This is a simple JSP demonstration page!";
            }
            
            public String getFormattedNumber(double number) {
                return String.format("%.2f", number);
            }
        %>
        
        <div class="info-box">
            <h3>JSP Features Demo</h3>
            <p><%= getWelcomeMessage() %></p>
            <p>Formatted PI value: <%= getFormattedNumber(Math.PI) %></p>
        </div>
        
        <footer style="text-align: center; margin-top: 30px; color: #666;">
            <p>&copy; 2024 Simple JSP Example | Powered by Java Server Pages</p>
        </footer>
    </div>
</body>
</html>
