FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["ddweb.csproj", "./"]
RUN dotnet restore "ddweb.csproj"
COPY . .
WORKDIR "/src/"
RUN dotnet build "ddweb.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ddweb.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Download and install the Tracer
RUN mkdir -p /opt/datadog
RUN mkdir -p /var/log/datadog 
RUN curl -LO https://github.com/DataDog/dd-trace-dotnet/releases/download/v2.35.0/datadog-dotnet-apm-2.35.0.arm64.tar.gz 
RUN tar -C /opt/datadog -xzf datadog-dotnet-apm-2.35.0.arm64.tar.gz && /opt/datadog/createLogPath.sh

# Enable the tracer
ENV CORECLR_ENABLE_PROFILING=1
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so
ENV DD_DOTNET_TRACER_HOME=/opt/datadog

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ddweb.dll"]
