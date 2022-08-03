import requests
import json
import maskpass
import base64
from requests.auth import HTTPBasicAuth
from Printer import Printer


class MonitPrinter(Printer):

    def __init__(self, report):
        super(MonitPrinter, self).__init__(report)
        self.target_address = 'https://monit-metrics:10012'

    def print_report(self):
        number_failed_scenarios = 0
        for scenario in list(self.report.report):
            if self.report.report[scenario]['status'] != 'PASS':
                number_failed_scenarios += 1

        status_message = self.get_status_message(number_failed_scenarios)
        self.send_and_check(status_message)

        return status_message

    def get_status_message(self, number_failed_scenarios):
        message = Debug(number_failed_scenarios)
        return [message]

    def send(self, document):
        self.get_credentials_from_enviroment_variables()
        return requests.post(self.target_address, auth=HTTPBasicAuth(self.username, self.password), data=json.dumps(document), headers={ "Content-Type": "application/json"})

    def send_and_check(self, document, should_fail=False):
        response = self.send(document)
        assert( (response.status_code in [200]) != should_fail), 'With document: {0}. Status code: {1}. Message: {2}'.format(document, response.status_code, response.text)

    def ask_credentials(self):
        print("\n========Create Account=========")
        self.username = input("Username : ")
        pwd = maskpass.askpass("Password : ")
        encpwd = base64.b64encode(pwd.encode("utf-8"))
        self.password = encpwd 

    def get_credentials_from_enviroment_variables(self):
        self.username = os.environ.get('CERN_USER')
        self.password = os.environ.get('CERN_PASSWORD').encode("utf-8")


class Message:


class AvalilabilityMessage(Message):

    def __init__(self, status):
        self.status = status
        self.template = {"producer": "volts", "type": "availability", "serviceid": "arealserviceid", "service_status": "unknown", "contact": "ihor.olkhovskyi@cern.ch"}

    def get_message(self):
        self.template[service_status] = f"{self.status}"
        return [self.template]


class DebugMessage(Message):

    def __init__(self, failed_tests):
        self.failed_tests = failed_tests
        self.template = { "producer": "debugger", "type": "failed_tests", "failed_tests": "unknown" }

    def get_message(self):
        self.template[failed_tests] = f"{self.failed_tests}"
        return [self.template]


class ServiceStatusFactory:
    
    def __init__(self, number_failed_scenarios):
        self.failed_scenarios = number_failed_scenarios


class TestThreshold(ServiceStatusFactory):

    def __init__(self, threshold, number_failed_scenarios):
        super(TestThreshold, self).__init__(number_failed_scenarios)
        self.threshold = threshold

    def get_status_message(self):
        if self.failed_scenarios > self.threshold: 
            message = AvailabilityMessage('unavailable')

        elif self.failed_scenarios == self.threshold: 
            message = AvailabilityMessage('degraded')

        else:
            message = AvailabilityMessage('available')

        return message.get_message()
        
class Debug(ServiceStatusFactory):

    def __init__(self, number_failed_scenarios):
        super(Debug, self).__init__(number_failed_scenarios)

    def get_status_message(self):
        message = DebugMessage(self.failed_scenarios)
        return message.get_status_message()
    

