<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>TaskFlow - Modern Task Manager</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(45deg, #ff6b6b, #ffa500);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        .stats {
            display: flex;
            justify-content: space-around;
            background: #f8f9fa;
            padding: 20px;
            border-bottom: 1px solid #eee;
        }
        
        .stat-card {
            text-align: center;
            padding: 15px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
            min-width: 100px;
        }
        
        .stat-number {
            font-size: 2rem;
            font-weight: bold;
            color: #667eea;
        }
        
        .content {
            padding: 30px;
        }
        
        .task-form {
            display: flex;
            gap: 10px;
            margin-bottom: 30px;
            flex-wrap: wrap;
        }
        
        .task-input {
            flex: 1;
            padding: 15px;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            font-size: 16px;
            min-width: 250px;
        }
        
        .priority-select {
            padding: 15px;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            font-size: 16px;
            background: white;
        }
        
        .add-btn {
            padding: 15px 25px;
            background: linear-gradient(45deg, #4CAF50, #45a049);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        .add-btn:hover {
            transform: translateY(-2px);
        }
        
        .task-list {
            display: grid;
            gap: 15px;
        }
        
        .task-item {
            background: white;
            padding: 20px;
            border-radius: 15px;
            border-left: 5px solid;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
            transition: transform 0.2s;
        }
        
        .task-item:hover {
            transform: translateY(-3px);
        }
        
        .task-high { border-left-color: #ff4757; }
        .task-medium { border-left-color: #ffa502; }
        .task-low { border-left-color: #2ed573; }
        
        .task-header {
            display: flex;
            justify-content: between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .task-title {
            font-size: 1.2rem;
            font-weight: bold;
            color: #2c3e50;
        }
        
        .priority-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
        }
        
        .priority-high { background: #ff4757; color: white; }
        .priority-medium { background: #ffa502; color: white; }
        .priority-low { background: #2ed573; color: white; }
        
        .task-time {
            color: #7f8c8d;
            font-size: 14px;
        }
        
        .progress-bar {
            width: 100%;
            height: 8px;
            background: #ecf0f1;
            border-radius: 4px;
            margin: 20px 0;
            overflow: hidden;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea, #764ba2);
            border-radius: 4px;
            transition: width 0.3s ease;
        }
        
        @media (max-width: 768px) {
            .task-form {
                flex-direction: column;
            }
            
            .stats {
                flex-direction: column;
                gap: 10px;
            }
        }
    </style>
</head>
<body>
    <%
        // Simulated task data - in a real app, this would come from a database
        List<Map<String, String>> tasks = new ArrayList<>();
        
        // Sample tasks
        Map<String, String> task1 = new HashMap<>();
        task1.put("id", "1");
        task1.put("title", "Deploy production release");
        task1.put("priority", "high");
        task1.put("time", "2 hours ago");
        tasks.add(task1);
        
        Map<String, String> task2 = new HashMap<>();
        task2.put("id", "2");
        task2.put("title", "Review code changes");
        task2.put("priority", "medium");
        task2.put("time", "4 hours ago");
        tasks.add(task2);
        
        Map<String, String> task3 = new HashMap<>();
        task3.put("id", "3");
        task3.put("title", "Update documentation");
        task3.put("priority", "low");
        task3.put("time", "1 day ago");
        tasks.add(task3);
        
        // Handle new task submission
        String newTask = request.getParameter("newTask");
        String priority = request.getParameter("priority");
        if (newTask != null && !newTask.trim().isEmpty()) {
            Map<String, String> task = new HashMap<>();
            task.put("id", String.valueOf(tasks.size() + 1));
            task.put("title", newTask.trim());
            task.put("priority", priority != null ? priority : "medium");
            task.put("time", "Just now");
            tasks.add(0, task); // Add to beginning of list
        }
        
        // Calculate stats
        int totalTasks = tasks.size();
        int highPriority = 0;
        int completedToday = (int)(Math.random() * 5) + 1;
        
        for (Map<String, String> task : tasks) {
            if ("high".equals(task.get("priority"))) {
                highPriority++;
            }
        }
        
        int progressPercentage = totalTasks > 0 ? (completedToday * 100) / (totalTasks + completedToday) : 0;
    %>
    
    <div class="container">
        <div class="header">
            <h1>TaskFlow</h1>
            <p>Streamline your productivity with smart task management</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-number"><%= totalTasks %></div>
                <div>Active Tasks</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= highPriority %></div>
                <div>High Priority</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= completedToday %></div>
                <div>Completed Today</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= progressPercentage %>%</div>
                <div>Progress</div>
            </div>
        </div>
        
        <div class="content">
            <form method="post" class="task-form">
                <input type="text" name="newTask" class="task-input" placeholder="What needs to be done?" required>
                <select name="priority" class="priority-select">
                    <option value="low">Low Priority</option>
                    <option value="medium" selected>Medium Priority</option>
                    <option value="high">High Priority</option>
                </select>
                <button type="submit" class="add-btn">Add Task</button>
            </form>
            
            <div class="progress-bar">
                <div class="progress-fill" style="width: <%= progressPercentage %>%"></div>
            </div>
            
            <div class="task-list">
                <% for (Map<String, String> task : tasks) { %>
                    <div class="task-item task-<%= task.get("priority") %>">
                        <div class="task-header">
                            <div class="task-title"><%= task.get("title") %></div>
                            <span class="priority-badge priority-<%= task.get("priority") %>">
                                <%= task.get("priority") %>
                            </span>
                        </div>
                        <div class="task-time">Created <%= task.get("time") %></div>
                    </div>
                <% } %>
                
                <% if (tasks.isEmpty()) { %>
                    <div style="text-align: center; padding: 40px; color: #7f8c8d;">
                        <h3>No tasks yet!</h3>
                        <p>Add your first task above to get started.</p>
                    </div>
                <% } %>
            </div>
        </div>
    </div>
</body>
</html>
