# nyann-bench with shell support
# Combines busybox (shell + utilities) with nyann-bench binary

FROM busybox:1.36

# Copy nyann-bench binary from the official image
COPY --from=ghcr.io/neuralmagic/nyann-bench:latest /nyann-bench /usr/local/bin/nyann-bench

# Verify binary is executable
RUN chmod +x /usr/local/bin/nyann-bench

# Default entrypoint is shell (allows running scripts)
ENTRYPOINT ["/bin/sh"]
