class Printer(object):

    def __init__(self, report):
        self.report = report

    def print_report(self):
        pass

    def filter_results_default(self, test_results):
        """
        Find all failed tests
        """
        printed_results = {}
        errors = list()

        for scenario_name, scenario_details in test_results.items():
            print("Processing {}".format(scenario_name))
            if scenario_details.get("status") == "PASS":
                continue
            printed_results[scenario_name] = {}
            printed_results[scenario_name]["status"] = scenario_details.get("status")
            printed_results[scenario_name]["status_text"] = scenario_details.get("status_text")
            printed_results[scenario_name]["start_time"] = scenario_details.get("start_time")
            printed_results[scenario_name]["end_time"] = scenario_details.get("end_time")
            printed_results[scenario_name]["task_counter"] = scenario_details.get("counter")

            errors.append(scenario_name)

            failed_tests = {}
            if scenario_details.get("tests"):
                for test_name, test_details in scenario_details["tests"].items():
                    if test_details.get("result") == "PASS":
                        continue
                    failed_tests[test_name] = test_details

            if len(failed_tests) > 1:
                printed_results[scenario_name]["failed_tests"] = failed_tests

        status = None
        if len(errors) > 0:
            status = errors

        return status, printed_results


