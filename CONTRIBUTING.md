# Contributions to BashToTheFuture

Thanks for your interest in contributing! If you are a collaborator with direct write access, we keep the process simple and fast while still protecting quality.

## Our workflow (Collaborators)

1. **Never commit directly to `main`**  
   `main` is protected and should only receive merged pull requests.
* Clone the repo first using by clicking "Code" and selecting the option for "HTTPS"" or "SSH" and then copy the link provided (SSH is preferred)
   ![alt text](https://raw.githubusercontent.com/jordanhall-it/bashtothefuture/refs/heads/Justin_Branch/photos/bashtothefuture_code_button.png)
* Next, run the following commands:
   ```bash
       # git clone git@github.com:jordanhall-it/bashtothefuture.git
2. **Create a Branch for Pull Request** for every change or addition to repo
   ```bash
   git checkout -b <insertbranchname>
        # e.g. git checkout -b jlewis/contributing_file
    # Make any changes or additions to the branch
    git add .
    git commit -m "Explain what you added here"
    git push origin <insertbranchname>
        # e.g. git push origin jlewis/contributing_file
3. **Keep branches short-lived**
    
    It is best practice to open a Pull Request (PR) within a few days after making changes.
4. **Open a Pull Request** (even if you're the maintainer)

* All changes go through PRs — no exceptions.
* Use the PR template if one exists.
* Assign at least one reviewer (or request review from the team).
* Mark as Draft if it's not ready for review yet.
5. **Testing**
* Add or update tests when relevant.
* Run the full test suite locally before requesting review:
    ```Bash
    npm test        # or yarn test, make test, etc.
6. **Code style & linting**
* Run the linter/formatter before pushing:Bashnpm run lint
    ```bash
    npm run format   # or prettier --write .
7. **Merging**
* We use "Squash and merge" (keeps history clean).
* Delete the branch after merging (GitHub can do it automatically).