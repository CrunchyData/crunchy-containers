package main

import "html/template"

var tmpl = template.Must(template.New("root").Parse(`
<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <title>Crunchy PostgreSQL Test Application</title>
    <meta name="description" content="Crunchy PostgreSQL Test Application">
    <meta name="author" content="Crunchy Data">
    <link rel="stylesheet" href="main.css">
</head>

<body>
  <div class="jumbotron" style="padding: 1em;background-color: #419bdc;border-radius: 0;"></div>

  <div class="container">
    <div class="text-center">
      <img src="https://www.crunchydata.com/images/original_logo.png" alt="Crunchy Data Logo" style="width: 10em;margin-bottom: 2rem;">
      <h1>Crunchy PostgreSQL Test Application</h1>
    </div>

    <hr>

    <h2>CRUD</h2>
    <table class="table table-striped">
      <thead class="thead-light">
        <tr>
          <th>Test</th>
          <th>Success</th>
          <th>Error</th>
        </tr>
      </thead>
      <tbody>
        {{range .CRUD}}
            <tr><td>{{.Name}}</td><td class="success">{{.Success}}</td><td>{{.Error}}</td></tr>
        {{end}}
      </tbody>
    </table>
    <h2>Databases</h2>
    <table class="table table-striped">
      <thead class="thead-light">
        <tr>
          <th>Name</th>
        </tr>
      </thead>
      <tbody>
        {{range .DB}}
            <tr><td>{{.Name}}</td></tr>
        {{end}}
      </tbody>
    </table>
    <h2>Extensions</h2>
    <table class="table table-striped">
      <thead class="thead-light">
        <tr>
          <th>Name</th>
          <th>Installed Version</th>
          <th>Default Version</th>
        </tr>
      </thead>
      <tbody>
        {{range .Extensions}}
            <tr><td>{{.Name}}</td><td>{{.InstalledVersion}}</td><td>{{.DefaultVersion}}</td></tr>
        {{end}}
      </tbody>
    </table>
    <h2>Roles</h2>
    <table class="table table-striped">
      <thead class="thead-light">
        <tr>
          <th>Name</th>
          <th>Superuser</th>
          <th>Create Role</th>
          <th>Create DB</th>
          <th>Login</th>
        </tr>
      </thead>
      <tbody>
        {{range .Roles}}
            <tr><td>{{.Name}}</td><td>{{.Super}}</td><td>{{.CreateRole}}</td><td>{{.CreateDB}}</td><td>{{.Login}}</td></tr>
        {{end}}
      </tbody>
    </table>
    <h2>Settings</h2>
    <table class="table table-striped">
      <thead class="thead-light">
        <tr>
          <th>Name</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        {{range .Settings}}
            <tr><td>{{.Name}}</td><td>{{.Value}}</td></tr>
        {{end}}
      </tbody>
    </table>
  </div>
</body>
</html>
`))
