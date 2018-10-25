---
title: "Trucos con AWS Lambda. (Parte 1)"
date: 2018-10-25T12:45:05-04:00
draft: false
tags: ['aws','lambda']
description: "Descubre como utilizar lambdas de forma ingeniosa."
---

## Truco 1: Recursividad asíncrona.

A veces queremos garantizar que una lambda se ejecute siempre de forma
asíncrona.

```python
def lambda_handler(event, context):
    if not event.get('async'):
        invoke_self_async(event, context)
        return

def invoke_self_async(event, context):
    new_event = {
        'async': True,
        'data': event
    }
    boto3.client('lambda').invoke_async(
        FunctionName=context.invoked_function_arn,
        InvokeArgs=json.dumps(new_event)
    )
```

Este truco es muy útil cuando no nos interesa el resultado de la ejecución o el
mismo es enviado por vías alternativas (ej. usando **SNS**)

## Truco 2: Planificación dinámica.

A veces la planificación de un servicio debe ser alterada en dependencia de ciertas condiciones.

```python
def lambda_handler(event, context):
    reschedule_event()
    keep_working()

REGULAR_SCHEDULE = 'rate(20 minutes)'
WEEKEND_SHEDULE = 'rate(1 hour)'
RULE_NAME = 'My Rule'

def reschedule_event():
    """
    Cambia la planificación de la lambda, para que descanse los findes :D
    """
    sched = boto3.client('events')
    current = sched.describe_rule(Name=RULE_NAME)
    if is_weekend() and 'minutes' in current['ScheduleExpression']:
        sched.put_rule(
            Name=RULE_NAME,
            ScheduleExpression=WEEKEND_SCHEDULE,
        )
    if not is_weekend and 'hour' in current['ScheduleExpression']:
        sched.put_rule(
            Name=RULE_NAME,
            ScheduleExpression=REGULAR_SCHEDULE,
        )
```

## Truco 3: Flujos de negocio

Cuando vayas a usar **StepFunctions** recuerda:

> Nunca uses un cañón para matar un mosquito

```python
def lambda_handler(event, context):
    return dispatch_workflow(event)

def dispatch_workflow(activity):
    workflow_id = event.get('workflow_id'):
    if workflow_id:
        # Retrieve the state from Dynamo
        state = get_saved_state(event['workflow_id'])
    else:
        workflow_id = create_workflow_id() # uuid maybe
        state = None
    workflow = Workflow(workflow_id)
    return workflow(state,events) # Workflow is a callable
```
