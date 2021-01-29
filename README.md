It is a fork with changes:

* added GUC store_last_plan (false by default)
  last plan is not saved, only first one, gets +30% increase.
* does not save queryID in its own format, gives up to +10% increase.
* added sample_rate (based on random).
* added slow_statement_duration - this is an unconditional logging of query plans longer than 
  the specified value.
* min_duration - now be specified as time.
* make fixes.