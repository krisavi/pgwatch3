import { useMutation, useQuery } from "@tanstack/react-query";
import { QueryKeys } from "consts/queryKeys";
import { Metrics } from "types/Metric/Metric";
import { MetricRequestBody } from "types/Metric/MetricRequestBody";
import MetricService from "services/Metric";
import { createMetricForm, updateMetricForm } from "../types/MetricTypes";
import { Metrics } from "layout/MetricDefinitions/MetricDefinitions.types";

const services = MetricService.getInstance();

export const useMetrics = () => useQuery<Metrics>({
  queryKey: QueryKeys.metric,
  queryFn: async () => await services.getMetrics()
});

export const useDeleteMetric = () => useMutation({
  mutationKey: [QueryKeys.Metric],
  mutationFn: async (data: string) => await services.deleteMetric(data)
});

export const useEditMetric = () => useMutation({
  mutationKey: [QueryKeys.Metric],
  mutationFn: async (data: MetricRequestBody) => await services.editMetric(data),
});

export const useAddMetric = () => useMutation({
  mutationKey: [QueryKeys.Metric],
  mutationFn: async (data: MetricRequestBody) => await services.addMetric(data),
});
