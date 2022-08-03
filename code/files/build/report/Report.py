import json
import os

class Report(object):

    def __init__(self, report_file_path):
        self.report_file_path = report_file_path
        self.report = self.get_report()


    def get_tests_list(self):
        """
        Function to get all tests lists from all tests directory.
        List of tests = list of directories
        """
        test_list = ['45-calendar-holidays-1', '25-blacklist-voicemail', '37-team-call-from-paused-member', '24-blacklist-hangup', '10-team-same-number', '01-register', '35-team-call-from-member', '27-team-custom-timeout', '20-call-check-callerid', '40-late-register-multi-call', '39-late-register-call', '41-register-db', '17-register-incorrect-2', '42-calendar-working-hours-1', '38-team-paused-forward', '26-call-change-callerid', '19-register-incorrect-4', '43-calendar-working-hours-2', '29-exten-timeout-2', '03-register-wait-for-call-1', '28-exten-timeout-1', '44-calendar-working-hours-3', '12-call-without-srtp', '16-register-incorect-1', '05-immediate-call-forward', '34-team-simul-call', '22-call-with-dtmf-incorrect', '07-delayed-call-forward', '46-calendar-holidays-2', '06-immediate-call-forward-chain', '08-team-single-member', '32-team-check-clid-1', '31-delayed-call-forward-setup', '30-exten-timeout-3', '33-team-check-clid-2', '15-register-call-delay-prov', '36-team-call-from-member-workgroup', '02-call-echo', '21-call-with-dtmf', '18-register-incorrect-3', '09-team-forward-member', '11-team-forwarded', '23-incorrect-dial', '04-register-wait-for-call-2', '14-register-multi-call', '13-register-multi']
        return test_list


    def get_report(self):
        with open(self.report_file_path) as report_file:
            process_error, report_data = self.process_jsonl_file(report_file)
            if process_error:
                raise Exception("Error processing report file: {}".format(process_error))

        tests_list = self.get_tests_list()
        test_results = self.build_test_results(report_data)
        return test_results


    def process_jsonl_file(self, file):
        """
        Function to process output of voip_patrol, which is JSONL (https://jsonlines.org/) file
        """
        processed_data = list()
        error = None

        for line in file:
            if len(line) <= 1:
                continue
            try:
                processed_data.append(json.loads(line))
            except ValueError as e:
                error = "Line {} is not a JSON".format(line)

        return error, processed_data


    def build_test_results(self, report_data):
        """
        Function to process line-by-line data from voip_patrol JSONL file
        to dict with structure
        "test_name": {
            "status": ...
            "start_time": ...
            "end_time": ...
            "tests": {
                ...
            }
        }
        """
        test_results = {}
        scenarios = self.slice_events(report_data)
        for scenario in scenarios:
            test_name = self._normalize_test_name(scenario[0]['scenario']['name'])
            if test_name in test_results:
                test_results[test_name]['status'] = 'FAIL'
                test_results[test_name]['status_text'] = 'Multiple starts'
                continue

            test_results[test_name] = self.get_scenario_dictionary(scenario)
        return test_results


    def slice_events(self, report):
        scenarios = []
        indexes = self.get_scenario_indexes(report)
        for start_event_index in range(0, len(indexes), 2):
            scenarios.append(report[indexes[start_event_index]:indexes[start_event_index + 1] + 1])

        return scenarios


    def get_scenario_dictionary(self, scenario_events):
        start = scenario_events.pop(0)['scenario']
        end = scenario_events.pop()['scenario']
        
        if start['name'] != end['name']:
            scenario['status'] = 'FAIL'
            scenario['status_text'] = 'Start/End are not aligned'
            return scenario

        scenario = {}
        scenario['start_time'] = start['time']
        scenario['tests'] = { list(test)[0] : test[list(test)[0]] for test in scenario_events }
        scenario['end_time'] = end['time']
        scenario['status'] = end.get('result', 'FAIL')
        scenario['counter'] = f"{end.get('total tasks', 'NA')}/{end.get('completed tasks', 'NA')}"
        scenario['status_text'] = 'Scenario passed'

        failed_test = 0
        for test in scenario_events: 
            if test[list(test)[0]]['result'] == 'FAIL':
                failed_test =+ 1
                scenario['status_text'] = f'{failed_test} test/s have failed'

        return scenario


    def get_scenario_indexes(self, report):
        return [ index for index, event in enumerate(report) if 'scenario' in event ]


    def _normalize_test_name(self, name):
        """
        Function to transform "/xml/<test_name>.xml" -> "<test_name>"
        """
        normalized_name = name.split("/")[-1]

        if normalized_name == 'voip_patrol.xml':
            normalized_name = name.split("/")[-2]

        if normalized_name.endswith('.xml'):
            return normalized_name[:-4]

        return normalized_name

