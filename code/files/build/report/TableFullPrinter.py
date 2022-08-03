from prettytable import PrettyTable
from Printer import Printer


class TableFullPrinter(Printer):

    def __init__(self, report):
        super(TableFullPrinter, self).__init__(report)

    def print_report(self):
        failed_scenarios, _ = self.filter_results_default(self.report.report)

        self.print_table()

        if failed_scenarios is not None:
            print("Scenarios {} are failed!".format(failed_scenarios))
            return

        print("All scenarios are OK!")

    def print_table(self):
        tbl = PrettyTable()
        tbl.field_names = ["Scenario", "Test", "Status", "Text"]

        for scenario_name, scenario_details in self.report.report.items():
            tbl.add_row([scenario_name, "", scenario_details.get("status"), scenario_details.get("status_text")])

            if not (type(scenario_details.get("tests")) is dict):
                continue

            for test_data in scenario_details.get("tests").values():
                tbl.add_row(["", test_data.get("label"), test_data.get("result"), test_data.get("result_text")])

        tbl.align = "r"
        print(tbl)

