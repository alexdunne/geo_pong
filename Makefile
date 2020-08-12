.PHONY: dev routes

dev: start_server

routes:
	mix phx.routes

start_server:
	mix phx.server
