# orgtodo

Easily create new TODO entry in an org file saved to Dropbox. Single input box UI to type your todo text. Single click sync. The application will add the `* TODO` bullet suffix and `SCHEDULE` the `TODO` for the next business day.

## Getting Started

Create a `config.yaml` file in a folder named `config` in the root of this application.
`config.yaml` should look like:
```yaml
app:
  properties:
    accessToken: 'My Dropbox Access Token'
    dropboxOrgFilePath: '/path/to/my/todo.org'
```
Where `accessToken` is an Application token registered in Dropbox and `dropboxOrgFilePath` is the path to an org file from the root of the `Dropbox` folder.
