<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*"%>
<%@ page import="java.sql.*"%>
<%@ page import="java.io.*"%>
<%@ page import="javax.crypto.*"%>
<%@ page import="java.security.*"%>
<%@ page import="java.util.regex.*"%>
<%@ page import="java.net.*"%>
<%@ page import="javax.xml.parsers.*"%>
<%@ page import="org.w3c.dom.*"%>
<%@ page import="javax.servlet.http.*"%>
<!DOCTYPE html>
<html>
<head>
    <title>High Severity Vulnerabilities Demo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
<%
    // ============================
    // CRITICAL SEVERITY SECRETS
    // ============================
    String awsAccessKeyId = "AKIAIOSFODNN7EXAMPLE";
    String awsSecretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
    String gitHubPersonalToken = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    String slackBotToken = "xoxb-xxxxxxxxxxxx-xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx";
    String stripeSecretKey = "sk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    String twilioAccountSid = "ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    String sendGridApiKey = "SG.xxxxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    String googleApiKey = "AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    String facebookAccessToken = "EAAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    String jwtSecretKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";
    
    // Database credentials
    String dbHost = "prod-db.company.com";
    String dbUser = "admin";
    String dbPass = "SuperSecret123!";
    String mongoUri = "mongodb://admin:password123@prod-mongo.company.com:27017/production";
    String redisPassword = "redis_prod_password_2024";
    
    // ============================
    // CRITICAL SQL INJECTION
    // ============================
    String userId = request.getParameter("userId");
    String email = request.getParameter("email");
    String role = request.getParameter("role");
    String orderBy = request.getParameter("sort");
    String limit = request.getParameter("limit");
    
    // Union-based SQL injection
    String unionQuery = "SELECT username, password FROM users WHERE id = " + userId + " UNION SELECT credit_card, cvv FROM payments";
    
    // Blind SQL injection
    String blindQuery = "SELECT * FROM users WHERE email = '" + email + "' AND (SELECT COUNT(*) FROM admin_users) > 0";
    
    // Boolean-based SQL injection
    String booleanQuery = "SELECT * FROM users WHERE role = '" + role + "' OR 1=1--";
    
    // Time-based SQL injection
    String timeQuery = "SELECT * FROM products ORDER BY " + orderBy + "; WAITFOR DELAY '00:00:10'--";
    
    // Second-order SQL injection
    String secondOrderQuery = "UPDATE user_preferences SET theme = '" + request.getParameter("theme") + "' WHERE user_id = " + userId;
    
    // ============================
    // CRITICAL XSS VULNERABILITIES
    // ============================
    String userComment = request.getParameter("comment");
    String searchTerm = request.getParameter("search");
    String userName = request.getParameter("name");
    String userBio = request.getParameter("bio");
    String customScript = request.getParameter("script");
    
    // ============================
    // REMOTE CODE EXECUTION
    // ============================
    String commandInput = request.getParameter("cmd");
    String fileToExecute = request.getParameter("file");
    String pythonCode = request.getParameter("python");
    String shellScript = request.getParameter("shell");
    
    if (commandInput != null) {
        try {
            Process proc = Runtime.getRuntime().exec("cmd.exe /c " + commandInput);
            BufferedReader reader = new BufferedReader(new InputStreamReader(proc.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                out.println(line + "<br>");
            }
        } catch (Exception e) {
            out.println("Command execution failed: " + e.getMessage());
        }
    }
    
    // ============================
    // DESERIALIZATION VULNERABILITY
    // ============================
    String serializedData = request.getParameter("data");
    if (serializedData != null) {
        try {
            byte[] data = Base64.getDecoder().decode(serializedData);
            ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(data));
            Object obj = ois.readObject(); // Unsafe deserialization
            ois.close();
        } catch (Exception e) {
            // Ignore errors
        }
    }
    
    // ============================
    // XXE (XML EXTERNAL ENTITY)
    // ============================
    String xmlInput = request.getParameter("xml");
    if (xmlInput != null) {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            // Vulnerable configuration - allows external entities
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", false);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", true);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", true);
            factory.setExpandEntityReferences(true);
            
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(new ByteArrayInputStream(xmlInput.getBytes()));
        } catch (Exception e) {
            out.println("XML Error: " + e.getMessage());
        }
    }
    
    // ============================
    // LDAP INJECTION
    // ============================
    String ldapUser = request.getParameter("username");
    String ldapPass = request.getParameter("password");
    if (ldapUser != null) {
        String ldapFilter = "(&(uid=" + ldapUser + ")(userPassword=" + ldapPass + "))";
        // This filter is vulnerable to LDAP injection
    }
    
    // ============================
    // PATH TRAVERSAL
    // ============================
    String requestedFile = request.getParameter("filename");
    if (requestedFile != null) {
        File file = new File("/var/www/uploads/" + requestedFile);
        if (file.exists()) {
            try (FileInputStream fis = new FileInputStream(file)) {
                byte[] buffer = new byte[1024];
                int bytesRead;
                while ((bytesRead = fis.read(buffer)) != -1) {
                    response.getOutputStream().write(buffer, 0, bytesRead);
                }
            } catch (IOException e) {
                out.println("File read error: " + e.getMessage());
            }
        }
    }
    
    // ============================
    // SSRF (Server-Side Request Forgery)
    // ============================
    String targetUrl = request.getParameter("url");
    if (targetUrl != null) {
        try {
            URL url = new URL(targetUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            
            BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            String line;
            StringBuilder content = new StringBuilder();
            while ((line = reader.readLine()) != null) {
                content.append(line);
            }
            reader.close();
            
            out.println("Response: " + content.toString());
        } catch (Exception e) {
            out.println("SSRF Error: " + e.getMessage());
        }
    }
    
    // ============================
    // WEAK CRYPTOGRAPHY
    // ============================
    try {
        // Using deprecated and weak algorithms
        Cipher desCipher = Cipher.getInstance("DES/ECB/PKCS5Padding");
        Cipher rc4Cipher = Cipher.getInstance("RC4");
        
        MessageDigest md5 = MessageDigest.getInstance("MD5");
        MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
        
        // Weak key generation
        KeyGenerator keyGen = KeyGenerator.getInstance("DES");
        keyGen.init(56); // Weak key size
        
        // Insecure random for cryptographic purposes
        Random weakRandom = new Random(System.currentTimeMillis());
        byte[] iv = new byte[8];
        weakRandom.nextBytes(iv);
        
    } catch (Exception e) {
        // Ignore errors
    }
    
    // ============================
    // INSECURE DIRECT OBJECT REFERENCE
    // ============================
    String documentId = request.getParameter("docId");
    String accountId = request.getParameter("accountId");
    if (documentId != null) {
        // No authorization check - anyone can access any document
        String documentPath = "/sensitive-docs/" + documentId + ".pdf";
        out.println("Document path: " + documentPath);
    }
    
    // ============================
    // AUTHENTICATION BYPASS
    // ============================
    String adminAction = request.getParameter("admin");
    if (adminAction != null) {
        // No authentication required for admin actions
        if ("deleteAllUsers".equals(adminAction)) {
            out.println("All users deleted!");
        } else if ("viewAllPasswords".equals(adminAction)) {
            out.println("Displaying all passwords...");
        }
    }
    
    // ============================
    // UNSAFE REFLECTION
    // ============================
    String className = request.getParameter("class");
    String methodName = request.getParameter("method");
    if (className != null && methodName != null) {
        try {
            Class<?> clazz = Class.forName(className);
            Object instance = clazz.getDeclaredConstructor().newInstance();
            java.lang.reflect.Method method = clazz.getMethod(methodName);
            Object result = method.invoke(instance);
            out.println("Result: " + result);
        } catch (Exception e) {
            out.println("Reflection error: " + e.getMessage());
        }
    }
    
    // ============================
    // COOKIE SECURITY ISSUES
    // ============================
    Cookie insecureCookie = new Cookie("sessionToken", "abc123");
    insecureCookie.setSecure(false);
    insecureCookie.setHttpOnly(false);
    insecureCookie.setMaxAge(-1);
    response.addCookie(insecureCookie);
    
    Cookie adminCookie = new Cookie("isAdmin", "true");
    adminCookie.setSecure(false);
    response.addCookie(adminCookie);
    
    // ============================
    // INFORMATION DISCLOSURE
    // ============================
    String debugInfo = System.getProperty("java.version") + " | " + 
                      System.getProperty("os.name") + " | " +
                      System.getProperty("user.home") + " | " +
                      request.getSession().getId();
%>

<h1>🚨 High Severity Vulnerabilities Test Page</h1>

<!-- REFLECTED XSS - CRITICAL -->
<h2>💥 Reflected XSS (CRITICAL)</h2>
<p>Welcome <%= userName %>!</p>
<p>Search results for: <%= searchTerm %></p>
<p>Comment: <%= userComment %></p>
<p>User bio: <%= userBio %></p>

<!-- DOM XSS -->
<div id="dynamic-content"></div>
<script>
    var userInput = '<%= request.getParameter("js") %>';
    document.getElementById('dynamic-content').innerHTML = userInput;
    
    // Execute user-provided script
    <% if (customScript != null) { %>
        <%= customScript %>
    <% } %>
    
    // Dangerous eval usage
    var code = new URLSearchParams(window.location.search).get('eval');
    if (code) {
        eval(code);
    }
</script>

<!-- SQL INJECTION FORMS - CRITICAL -->
<h2>💉 SQL Injection Test Forms (CRITICAL)</h2>
<form method="get">
    <input type="text" name="userId" placeholder="User ID" value="<%= userId %>">
    <input type="text" name="email" placeholder="Email" value="<%= email %>">
    <input type="text" name="role" placeholder="Role" value="<%= role %>">
    <button type="submit">Submit (SQL Injectable)</button>
</form>

<p><strong>Generated Queries:</strong></p>
<ul>
    <li>Union Query: <%= unionQuery %></li>
    <li>Blind Query: <%= blindQuery %></li>
    <li>Boolean Query: <%= booleanQuery %></li>
    <li>Time Query: <%= timeQuery %></li>
</ul>

<!-- REMOTE CODE EXECUTION - CRITICAL -->
<h2>⚡ Remote Code Execution (CRITICAL)</h2>
<form method="get">
    <input type="text" name="cmd" placeholder="Command to execute">
    <button type="submit">Execute Command</button>
</form>

<form method="get">
    <input type="text" name="file" placeholder="Script file to run">
    <button type="submit">Run Script</button>
</form>

<!-- FILE UPLOAD - CRITICAL -->
<h2>📁 Unrestricted File Upload (CRITICAL)</h2>
<form method="post" enctype="multipart/form-data">
    <input type="file" name="uploadedFile" accept="*">
    <button type="submit">Upload Executable File</button>
</form>

<!-- SSRF - HIGH -->
<h2>🌐 Server-Side Request Forgery (HIGH)</h2>
<form method="get">
    <input type="url" name="url" placeholder="URL to fetch" value="http://169.254.169.254/latest/meta-data/">
    <button type="submit">Fetch URL (SSRF)</button>
</form>

<!-- XXE - HIGH -->
<h2>📄 XML External Entity (XXE) (HIGH)</h2>
<form method="post">
    <textarea name="xml" rows="10" cols="80" placeholder="Enter XML with external entities">
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<root>&xxe;</root>
    </textarea>
    <button type="submit">Process XML</button>
</form>

<!-- DESERIALIZATION - CRITICAL -->
<h2>🔄 Insecure Deserialization (CRITICAL)</h2>
<form method="get">
    <input type="text" name="data" placeholder="Base64 encoded serialized object">
    <button type="submit">Deserialize Object</button>
</form>

<!-- PATH TRAVERSAL - HIGH -->
<h2>📂 Path Traversal (HIGH)</h2>
<form method="get">
    <input type="text" name="filename" placeholder="Filename" value="../../../etc/passwd">
    <button type="submit">Download File</button>
</form>

<!-- LDAP INJECTION - MEDIUM -->
<h2>🗂️ LDAP Injection (MEDIUM)</h2>
<form method="get">
    <input type="text" name="username" placeholder="Username">
    <input type="password" name="password" placeholder="Password">
    <button type="submit">LDAP Login</button>
</form>

<!-- UNSAFE REFLECTION - HIGH -->
<h2>🔍 Unsafe Reflection (HIGH)</h2>
<form method="get">
    <input type="text" name="class" placeholder="Class name" value="java.lang.Runtime">
    <input type="text" name="method" placeholder="Method name" value="getRuntime">
    <button type="submit">Invoke Method</button>
</form>

<!-- ADMIN BYPASS - CRITICAL -->
<h2>🔑 Authentication Bypass (CRITICAL)</h2>
<form method="get">
    <select name="admin">
        <option value="">Select admin action...</option>
        <option value="deleteAllUsers">Delete All Users</option>
        <option value="viewAllPasswords">View All Passwords</option>
        <option value="shutdownServer">Shutdown Server</option>
    </select>
    <button type="submit">Execute Admin Action (No Auth Required)</button>
</form>

<!-- SENSITIVE DATA EXPOSURE -->
<h2>🔍 Sensitive Information Disclosure</h2>
<div style="background:#ffeeee;padding:20px;border:1px solid red;">
    <h3>🚨 EXPOSED SECRETS:</h3>
    <p><strong>AWS Access Key:</strong> <%= awsAccessKeyId %></p>
    <p><strong>AWS Secret Key:</strong> <%= awsSecretAccessKey %></p>
    <p><strong>GitHub Token:</strong> <%= gitHubPersonalToken %></p>
    <p><strong>Stripe Secret:</strong> <%= stripeSecretKey %></p>
    <p><strong>JWT Secret:</strong> <%= jwtSecretKey %></p>
    <p><strong>Database Password:</strong> <%= dbPass %></p>
    <p><strong>MongoDB URI:</strong> <%= mongoUri %></p>
    <p><strong>Debug Info:</strong> <%= debugInfo %></p>
</div>

<!-- JavaScript Vulnerabilities -->
<script>
    // Prototype pollution
    function merge(target, source) {
        for (var key in source) {
            if (source.hasOwnProperty(key)) {
                target[key] = source[key];
            }
        }
    }
    
    // Client-side storage of sensitive data
    localStorage.setItem('aws-key', '<%= awsAccessKeyId %>');
    localStorage.setItem('db-password', '<%= dbPass %>');
    sessionStorage.setItem('jwt-secret', '<%= jwtSecretKey %>');
    
    // Insecure random token generation
    function generateToken() {
        return Math.random().toString(36).substr(2, 9);
    }
    
    // Direct DOM manipulation with user input
    var params = new URLSearchParams(window.location.search);
    var content = params.get('content');
    if (content) {
        document.body.innerHTML += content;
    }
</script>

</body>
</html>
