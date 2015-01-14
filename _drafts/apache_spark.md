how to setup apache spark

- make sure we have java - java -version
- download apache spark prebuilt (because I just want to start doing something) for the latest hadoop (https://spark.apache.org/downloads.html)
- tar -xzvf spark-1.2.0-bin-hadoop2.4.tgz
- Let's test this for the first time and run an example - ./bin/run-example SparkPi 10 - calculate PI with 10 workers.
- Dozens of log messages and almost at the end: "Pi is roughly 3.140612". I guess it worked.
- Let's just stop for a moment and understand what just happened. With my limited and just acquired knowledge, here's what I think happened:
  - Apache Spark ran the scala class SparkPi connected to a local cluster.
  - It then sent the JAR file with the class to the worker nodes.
  - The class takes the argument passed to it and parallelizes the calculation into **n** number of tasks (since it was local, tasks = threads)
  - After that, the reduce method triggers a job to start and sends the **n** tasks to be executed.
    INFO SparkContext: Starting job: reduce at SparkPi.scala:35
    (...)
    INFO TaskSchedulerImpl: Adding task set 0.0 with 10 tasks
  - The tasks finish one by one
    INFO TaskSetManager: Finished task 3.0 in stage 0.0 (TID 3) in 967 ms on localhost (1/10)
  - Until the job completes and the result is printed
    INFO DAGScheduler: Job 0 finished: reduce at SparkPi.scala:35, took 1.343225 s
    Pi is roughly 3.143028

  - Side note: All examples come in a JAR in the lib folder. I expected the command to fail at first because I did not have Scala installed yet. I was confused when instead it ran beautifully. So I had to go digging to try to understand what happened. bin/run-example was the answer.
