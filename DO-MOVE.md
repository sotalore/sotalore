
# New APP

  - generally all the defaults
  - need a `SPACES_KEY` and `SPACES_SECRET` once that is integrated
  - a managed database (not a dev) is likely easier
  - The default command is `rails server` is this puma? it looks like it is.

# For migrations...

  - Create a new Componenet
  - make it a pre-deploy job
  - command: rails db:migrate


# Load Balancing

  - automatic on app-platform
  - https://www.digitalocean.com/docs/app-platform/concepts/load-balancer/

# Domain

  - Simple CNAME with Cloudflare seems to work just fine.


# Rails Console

  - To be solved, currently can be done via the web