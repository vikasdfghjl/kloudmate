from opentelemetry import trace, metrics

from random import randint
from flask import Flask

tracer = trace.get_tracer("diceroller.tracer")

meter = metrics.get_meter("diceroller.meter")

roll_counter = meter.create_counter(
 "roll_counter",
 description="The number of rolls by roll value",
)

app = Flask(__name__)

@app.route("/health")
def health():
 return {"status": "healthy", "service": "dice-server"}, 200

@app.route("/rolldice")
def roll_dice():
 return str(do_roll())

def do_roll():
 with tracer.start_as_current_span("do_roll") as rollspan:
  res = randint(1, 6)
  rollspan.set_attribute("roll.value", res)
  roll_counter.add(1, {"roll.value": res})
  return res