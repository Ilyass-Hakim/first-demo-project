<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Student Grade Calculator</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(45deg, #4CAF50, #45a049);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .content {
            padding: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #333;
        }
        input[type="text"], input[type="number"], select {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        input[type="text"]:focus, input[type="number"]:focus, select:focus {
            border-color: #4CAF50;
            outline: none;
        }
        .btn {
            background: #4CAF50;
            color: white;
            padding: 12px 25px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            margin-right: 10px;
            transition: background 0.3s;
        }
        .btn:hover {
            background: #45a049;
        }
        .btn-danger {
            background: #f44336;
        }
        .btn-danger:hover {
            background: #da190b;
        }
        .student-card {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 10px;
            padding: 20px;
            margin: 15px 0;
            transition: transform 0.2s;
        }
        .student-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .grade-a { border-left: 5px solid #4CAF50; }
        .grade-b { border-left: 5px solid #2196F3; }
        .grade-c { border-left: 5px solid #FF9800; }
        .grade-d { border-left: 5px solid #f44336; }
        .grade-f { border-left: 5px solid #9C27B0; }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <%
        // Initialize or get student list from session
        List<Map<String, Object>> students = (List<Map<String, Object>>) session.getAttribute("students");
        if (students == null) {
            students = new ArrayList<>();
            session.setAttribute("students", students);
        }
        
        // Handle form submission
        String action = request.getParameter("action");
        String studentName = request.getParameter("studentName");
        String mathScoreStr = request.getParameter("mathScore");
        String englishScoreStr = request.getParameter("englishScore");
        String scienceScoreStr = request.getParameter("scienceScore");
        
        if ("add".equals(action) && studentName != null && !studentName.trim().isEmpty()) {
            try {
                double mathScore = Double.parseDouble(mathScoreStr);
                double englishScore = Double.parseDouble(englishScoreStr);
                double scienceScore = Double.parseDouble(scienceScoreStr);
                
                double average = (mathScore + englishScore + scienceScore) / 3.0;
                String letterGrade = getLetterGrade(average);
                
                Map<String, Object> student = new HashMap<>();
                student.put("name", studentName);
                student.put("math", mathScore);
                student.put("english", englishScore);
                student.put("science", scienceScore);
                student.put("average", average);
                student.put("grade", letterGrade);
                student.put("timestamp", new Date());
                
                students.add(student);
            } catch (NumberFormatException e) {
                // Handle invalid number input
            }
        }
        
        if ("clear".equals(action)) {
            students.clear();
        }
        
        // Calculate statistics
        double classAverage = 0;
        int totalStudents = students.size();
        Map<String, Integer> gradeDistribution = new HashMap<>();
        gradeDistribution.put("A", 0);
        gradeDistribution.put("B", 0);
        gradeDistribution.put("C", 0);
        gradeDistribution.put("D", 0);
        gradeDistribution.put("F", 0);
        
        if (totalStudents > 0) {
            double sum = 0;
            for (Map<String, Object> student : students) {
                sum += (Double) student.get("average");
                String grade = (String) student.get("grade");
                gradeDistribution.put(grade, gradeDistribution.get(grade) + 1);
            }
            classAverage = sum / totalStudents;
        }
    %>
    
    <%!
        // Method to calculate letter grade
        public String getLetterGrade(double average) {
            if (average >= 90) return "A";
            else if (average >= 80) return "B";
            else if (average >= 70) return "C";
            else if (average >= 60) return "D";
            else return "F";
        }
        
        public String getGradeClass(String grade) {
            switch(grade) {
                case "A": return "grade-a";
                case "B": return "grade-b";
                case "C": return "grade-c";
                case "D": return "grade-d";
                default: return "grade-f";
            }
        }
    %>
    
    <div class="container">
        <div class="header">
            <h1>🎓 Student Grade Calculator</h1>
            <p>Track and manage student performance across subjects</p>
        </div>
        
        <div class="content">
            <!-- Add Student Form -->
            <form method="post" action="">
                <input type="hidden" name="action" value="add">
                
                <div class="form-group">
                    <label for="studentName">Student Name:</label>
                    <input type="text" id="studentName" name="studentName" required 
                           placeholder="Enter student's full name">
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px;">
                    <div class="form-group">
                        <label for="mathScore">Math Score:</label>
                        <input type="number" id="mathScore" name="mathScore" 
                               min="0" max="100" step="0.1" required placeholder="0-100">
                    </div>
                    
                    <div class="form-group">
                        <label for="englishScore">English Score:</label>
                        <input type="number" id="englishScore" name="englishScore" 
                               min="0" max="100" step="0.1" required placeholder="0-100">
                    </div>
                    
                    <div class="form-group">
                        <label for="scienceScore">Science Score:</label>
                        <input type="number" id="scienceScore" name="scienceScore" 
                               min="0" max="100" step="0.1" required placeholder="0-100">
                    </div>
                </div>
                
                <button type="submit" class="btn">Add Student</button>
                <button type="submit" name="action" value="clear" class="btn btn-danger" 
                        onclick="return confirm('Are you sure you want to clear all students?')">
                    Clear All
                </button>
            </form>
            
            <!-- Statistics -->
            <% if (totalStudents > 0) { %>
                <div class="stats">
                    <div class="stat-card">
                        <div class="stat-number"><%= totalStudents %></div>
                        <div>Total Students</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number"><%= String.format("%.1f", classAverage) %></div>
                        <div>Class Average</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number"><%= gradeDistribution.get("A") %></div>
                        <div>A Grades</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number"><%= gradeDistribution.get("F") %></div>
                        <div>F Grades</div>
                    </div>
                </div>
            <% } %>
            
            <!-- Student List -->
            <h2>Student Records (<%= totalStudents %> students)</h2>
            
            <% if (totalStudents == 0) { %>
                <div class="student-card">
                    <p style="text-align: center; color: #666; font-style: italic;">
                        No students added yet. Use the form above to add your first student!
                    </p>
                </div>
            <% } else { %>
                <% for (Map<String, Object> student : students) { %>
                    <div class="student-card <%= getGradeClass((String) student.get("grade")) %>">
                        <h3 style="margin: 0 0 15px 0; color: #333;">
                            <%= student.get("name") %> 
                            <span style="float: right; font-size: 1.5em; font-weight: bold;">
                                <%= student.get("grade") %>
                            </span>
                        </h3>
                        <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px;">
                            <div>
                                <strong>Math:</strong><br>
                                <%= String.format("%.1f", (Double) student.get("math")) %>%
                            </div>
                            <div>
                                <strong>English:</strong><br>
                                <%= String.format("%.1f", (Double) student.get("english")) %>%
                            </div>
                            <div>
                                <strong>Science:</strong><br>
                                <%= String.format("%.1f", (Double) student.get("science")) %>%
                            </div>
                            <div>
                                <strong>Average:</strong><br>
                                <span style="font-size: 1.2em; font-weight: bold;">
                                    <%= String.format("%.1f", (Double) student.get("average")) %>%
                                </span>
                            </div>
                        </div>
                        <div style="margin-top: 10px; font-size: 0.9em; color: #666;">
                            Added: <%= student.get("timestamp") %>
                        </div>
                    </div>
                <% } %>
            <% } %>
        </div>
    </div>
</body>
</html>
