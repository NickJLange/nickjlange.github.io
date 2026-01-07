.PHONY: all clean build serve render-cv install-deps

# Default target
all: build

# Install dependencies
install-deps:
	@echo "Installing Ruby dependencies..."
	@if [ ! -f Gemfile ]; then \
		echo 'source "https://rubygems.org"' > Gemfile; \
		echo 'gem "jekyll", "~> 4.3"' >> Gemfile; \
		echo 'gem "webrick"' >> Gemfile; \
	fi
	@gem install bundler 2>/dev/null || true
	@bundle install

# Render CV from YAML to HTML/PDF
render-cv:
	@echo "Rendering CV..."
	@cd resume/cv && rendercv render Nick_J._Lange_CV.yaml
	@mkdir -p assets
	@cp resume/cv/rendercv_output/Nick_J_Lange_CV.pdf assets/resume.pdf
	@cp resume/cv/rendercv_output/Nick_J_Lange_CV.html assets/resume.html
	@echo "CV rendered to assets/"

# Build the Jekyll site
build: render-cv install-deps
	@echo "Building Jekyll site..."
	@bundle exec jekyll build
	@echo "Site built to _site/"

# Serve the site locally
serve: render-cv install-deps
	@echo "Starting Jekyll server..."
	@bundle exec jekyll serve --livereload

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf _site
	@rm -rf assets/resume.pdf assets/resume.html
	@rm -rf resume/cv/rendercv_output
	@rm -rf .jekyll-cache
	@echo "Clean complete"

# Help target
help:
	@echo "Available targets:"
	@echo "  make all          - Build the complete site (default)"
	@echo "  make build        - Build the Jekyll site with rendered CV"
	@echo "  make serve        - Build and serve the site locally with live reload"
	@echo "  make render-cv    - Render CV from YAML to HTML/PDF"
	@echo "  make install-deps - Install Ruby/Jekyll dependencies"
	@echo "  make clean        - Remove all build artifacts"
	@echo "  make help         - Show this help message"
