FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/Gateway/Ocelot.Gateway/Ocelot.Gateway.csproj", "src/Gateway/Ocelot.Gateway/"]
COPY ["src/Shared/Shared.Observability/Shared.Observability.csproj", "src/Shared/Shared.Observability/"]
RUN dotnet restore "src/Gateway/Ocelot.Gateway/Ocelot.Gateway.csproj"
COPY . .
WORKDIR "/src/src/Gateway/Ocelot.Gateway"
RUN dotnet build "Ocelot.Gateway.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Ocelot.Gateway.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Ocelot.Gateway.dll"]

