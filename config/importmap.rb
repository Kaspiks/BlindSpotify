pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"

pin "@rails/actioncable", to: "actioncable.esm.js"

# Tom Select – searchable select dropdowns (vendored locally)
pin "tom-select", to: "tom-select.js"
