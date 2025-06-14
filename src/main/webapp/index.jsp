<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dynamic JSP Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            margin-bottom: 30px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        
        .header h1 {
            color: #4a5568;
            font-size: 2.5em;
            margin-bottom: 10px;
            font-weight: 700;
        }
        
        .header .subtitle {
            color: #718096;
            font-size: 1.1em;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px;
            margin-bottom: 30px;
        }
        
        .card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 25px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.15);
        }
        
        .card h3 {
            color: #2d3748;
            margin-bottom: 15px;
            font-size: 1.4em;
            font-weight: 600;
        }
        
        .info-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        
        .info-item:last-child {
            border-bottom: none;
        }
        
        .info-label {
            font-weight: 600;
            color: #4a5568;
        }
        
        .info-value {
            color: #667eea;
            font-weight: 500;
        }
        
        .form-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1);
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2d3748;
        }
        
        .form-group input, .form-group select, .form-group textarea {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            font-size: 16px;
            transition: border-color 0.3s ease, box-shadow 0.3s ease;
        }
        
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
        }
        
        .result {
            background: #f0fff4;
            border: 2px solid #68d391;
            border-radius: 12px;
            padding: 15px;
            margin-top: 20px;
            color: #22543d;
        }
        
        .random-facts {
            list-style: none;
        }
        
        .random-facts li {
            padding: 12px;
            margin: 8px 0;
            background: #f7fafc;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 15px;
            }
            
            .header h1 {
                font-size: 2em;
            }
            
            .grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <%
        // JSP Scriptlet - Java code embedded in JSP
        Date currentDate = new Date();
        SimpleDateFormat formatter = new SimpleDateFormat("EEEE, MMMM dd, yyyy 'at' HH:mm:ss");
        String formattedDate = formatter.format(currentDate);
        
        // Get server information
        String serverInfo = application.getServerInfo();
        String contextPath = request.getContextPath();
        String sessionId = session.getId();
        String userAgent = request.getHeader("User-Agent");
        String remoteAddr = request.getRemoteAddr();
        
        // Random facts array
        String[] facts = {
            "Honey never spoils - archaeologists have found edible honey in ancient Egyptian tombs!",
            "A group of flamingos is called a 'flamboyance'.",
            "Bananas are berries, but strawberries aren't!",
            "Octopuses have three hearts and blue blood.",
            "A day on Venus is longer than its year.",
            "Wombat droppings are cube-shaped.",
            "There are more possible games of chess than atoms in the observable universe."
        };
        
        // Handle form submission
        String userName = request.getParameter("userName");
        String userAge = request.getParameter("userAge");
        String userColor = request.getParameter("userColor");
        String userMessage = request.getParameter("userMessage");
        
        boolean formSubmitted = (userName != null && !userName.trim().isEmpty());
    %>
    
    <div class="container">
        <div class="header">
            <h1>🚀 Dynamic JSP Dashboard</h1>
            <p class="subtitle">Powered by Java Server Pages Technology</p>
            <p style="margin-top: 10px; font-style: italic;"><%= formattedDate %></p>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>📊 Server Information</h3>
                <div class="info-item">
                    <span class="info-label">Server:</span>
                    <span class="info-value"><%= serverInfo %></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Context Path:</span>
                    <span class="info-value"><%= contextPath.isEmpty() ? "/" : contextPath %></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Session ID:</span>
                    <span class="info-value"><%= sessionId.substring(0, Math.min(8, sessionId.length())) %>...</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Your IP:</span>
                    <span class="info-value"><%= remoteAddr %></span>
                </div>
            </div>
            
            <div class="card">
                <h3>🎲 Random Fact Generator</h3>
                <div style="text-align: center; margin: 20px 0;">
                    <p style="font-style: italic; color: #4a5568; margin-bottom: 15px;">Did you know?</p>
                    <div style="background: #f7fafc; padding: 15px; border-radius: 12px; border-left: 4px solid #667eea;">
                        <%= facts[(int)(Math.random() * facts.length)] %>
                    </div>
                    <form method="post" style="margin-top: 15px;">
                        <button type="submit" class="btn">🔄 Get New Fact</button>
                    </form>
                </div>
            </div>
            
            <div class="card">
                <h3>🔢 Math Operations</h3>
                <%
                    int num1 = (int)(Math.random() * 100) + 1;
                    int num2 = (int)(Math.random() * 100) + 1;
                    int sum = num1 + num2;
                    int product = num1 * num2;
                    double average = (num1 + num2) / 2.0;
                %>
                <div class="info-item">
                    <span class="info-label">Random Numbers:</span>
                    <span class="info-value"><%= num1 %> & <%= num2 %></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Sum:</span>
                    <span class="info-value"><%= sum %></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Product:</span>
                    <span class="info-value"><%= product %></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Average:</span>
                    <span class="info-value"><%= String.format("%.1f", average) %></span>
                </div>
            </div>
            
            <div class="card">
                <h3>📅 Date & Time Info</h3>
                <%
                    Calendar cal = Calendar.getInstance();
                    String dayOfWeek = new SimpleDateFormat("EEEE").format(cal.getTime());
                    String month = new SimpleDateFormat("MMMM").format(cal.getTime());
                    int dayOfMonth = cal.get(Calendar.DAY_OF_MONTH);
                    int year = cal.get(Calendar.YEAR);
                    int hour = cal.get(Calendar.HOUR_OF_DAY);
                    String timeOfDay = hour < 12 ? "Morning" : hour < 17 ? "Afternoon" : "Evening";
                %>
                <div class="info-item">
                    <span class="info-label">Day:</span>
                    <span class="info-value"><%= dayOfWeek %></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Month:</span>
                    <span class="info-value"><%= month %></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Year:</span>
                    <span class="info-value"><%= year %></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Time of Day:</span>
                    <span class="info-value"><%= timeOfDay %></span>
                </div>
            </div>
        </div>
        
        <div class="form-card">
            <h3>👤 User Information Form</h3>
            <form method="post">
                <div class="form-group">
                    <label for="userName">Your Name:</label>
                    <input type="text" id="userName" name="userName" required 
                           value="<%= userName != null ? userName : "" %>">
                </div>
                
                <div class="form-group">
                    <label for="userAge">Your Age:</label>
                    <input type="number" id="userAge" name="userAge" min="1" max="120" 
                           value="<%= userAge != null ? userAge : "" %>">
                </div>
                
                <div class="form-group">
                    <label for="userColor">Favorite Color:</label>
                    <select id="userColor" name="userColor">
                        <option value="">Select a color...</option>
                        <option value="Red" <%= "Red".equals(userColor) ? "selected" : "" %>>Red</option>
                        <option value="Blue" <%= "Blue".equals(userColor) ? "selected" : "" %>>Blue</option>
                        <option value="Green" <%= "Green".equals(userColor) ? "selected" : "" %>>Green</option>
                        <option value="Purple" <%= "Purple".equals(userColor) ? "selected" : "" %>>Purple</option>
                        <option value="Orange" <%= "Orange".equals(userColor) ? "selected" : "" %>>Orange</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="userMessage">Tell us something about yourself:</label>
                    <textarea id="userMessage" name="userMessage" rows="4"><%= userMessage != null ? userMessage : "" %></textarea>
                </div>
                
                <button type="submit" class="btn">Submit Information</button>
            </form>
            
            <% if (formSubmitted) { %>
                <div class="result">
                    <h4>🎉 Thank You for Your Information!</h4>
                    <p><strong>Name:</strong> <%= userName %></p>
                    <% if (userAge != null && !userAge.isEmpty()) { %>
                        <p><strong>Age:</strong> <%= userAge %> years old</p>
                        <% 
                            int age = Integer.parseInt(userAge);
                            String ageGroup = age < 18 ? "Young Explorer" : 
                                            age < 30 ? "Rising Star" : 
                                            age < 50 ? "Experienced Professional" : 
                                            age < 70 ? "Wise Mentor" : "Life Master";
                        %>
                        <p><strong>Age Group:</strong> <%= ageGroup %></p>
                    <% } %>
                    <% if (userColor != null && !userColor.isEmpty()) { %>
                        <p><strong>Favorite Color:</strong> <span style="color: <%= userColor.toLowerCase() %>; font-weight: bold;"><%= userColor %></span></p>
                    <% } %>
                    <% if (userMessage != null && !userMessage.trim().isEmpty()) { %>
                        <p><strong>Your Message:</strong> "<%= userMessage %>"</p>
                    <% } %>
                    <p><em>Information submitted at: <%= formattedDate %></em></p>
                </div>
            <% } %>
        </div>
    </div>
    
    <script>
        // Add some interactive JavaScript
        document.addEventListener('DOMContentLoaded', function() {
            // Add smooth scrolling
            const cards = document.querySelectorAll('.card');
            cards.forEach(card => {
                card.addEventListener('mouseenter', function() {
                    this.style.transform = 'translateY(-5px) scale(1.02)';
                });
                card.addEventListener('mouseleave', function() {
                    this.style.transform = 'translateY(0) scale(1)';
                });
            });
            
            // Add form validation feedback
            const form = document.querySelector('form');
            const inputs = form.querySelectorAll('input, select, textarea');
            
            inputs.forEach(input => {
                input.addEventListener('blur', function() {
                    if (this.value && this.checkValidity()) {
                        this.style.borderColor = '#68d391';
                    } else if (!this.checkValidity()) {
                        this.style.borderColor = '#fc8181';
                    }
                });
            });
        });
    </script>
</body>
</html>
