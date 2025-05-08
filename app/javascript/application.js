// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import "trix"
import "@rails/actiontext"
import "chartkick/chart.js"


Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target);
};
