Most units contained in this repo do not really depict a well-formed & intended
use-case for `systemd --user`. In fact, most of the trivial well-formed `user/`
units (like [gpg-agent.service](https://github.com/intelfx/user-systemd-units/blob/f1b020b6d11da3e7cb01c56dc17f178d134ac860/user/gpg-agent.service)
and friends, [pulseaudio.service](https://github.com/intelfx/user-systemd-units/blob/9fb9a7ae3c2643971e52c10b1c5bb7664fcb947f/user/pulseaudio.service) etc.)
already got included in their respective upstream projects and were
correspondingly dropped from here.

Instead, this repo is an (unmaintained) attempt to have a completely
`systemd --user`-driven user *session*. I'll try to explain what is going on,
esp. since this repo got mentioned in a certain lecture series on GNU/Linux
userspace.

# Concepts

As far as `systemd` is concerned, processes run in three different "scopes"
("scopes" in abstract sense, not related to `.scope` units, although they do
reflect this hierarchy to some degree):

* system-wide services,
* per-user services, and
* user sessions.

The system-wide services are things directly launched by the PID 1, in a clean
environment and "system-wide lifetime". These processes are not bound to any
user or any login session and cannot be meaningfully made so because they are in
an "enclosing lifetime". For example, you cannot make a system-wide service
launching some X program for your graphical login session, because at the moment
system services are started there are no user logins and no `$DISPLAY` to talk
to.

The per-user services are launched by `systemd --user` instances which are
started *once per user*, either directly preceding their first login or as part
of general boot sequence if "lingering" (`loginctl enable-linger`) is enabled
for a user. If "lingering" is not enabled, the `systemd --user` instance is
started by PAM (`pam_systemd.so`) as part of user login.

Regardless of this, `systemd --user` proceeds to activate its `default.target`.
Moreover, PAM will not return control to the calling application until the
per-user `basic.target` is reached.
