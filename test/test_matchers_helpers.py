from meld.matchers.helpers import CachedSequenceMatcher


class Scheduler:

    def add_task(self, task):
        raise AssertionError("small matches must not schedule a worker task")


def test_small_match_does_not_start_worker():
    matcher = CachedSequenceMatcher(Scheduler())
    try:
        matcher.match("before", "after", lambda opcodes: None)

        assert matcher.thread.pid is None
        assert ("before", "after") in matcher.cache
    finally:
        matcher.stop()
