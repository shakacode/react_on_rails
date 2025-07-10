# Convert Rails 5 API only app to a Rails app

1. Go to the directory where you created your app

```bash
$ rails new your-current-app-name
```

Rails will start creating the app and will skip the files you have already created. If there is some conflict then it will stop and you need to resolve it manually. be careful at this step as it might replace you current code in conflicted files.

2. Resolve conflicts

```
1. Press "d" to see the difference
2. If it is only adding lines then press "y" to continue
3. If it is removeing some of your code then press "n" and add all additions manually
```

3. Run `bundle install` and follow [the instructions for installing into an existing Rails app](../guides/installation-into-an-existing-rails-app.md)
